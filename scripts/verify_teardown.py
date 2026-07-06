"""
verify_teardown.py — confirms that `terraform destroy` actually removed
every billable resource it created.

Why this exists: `terraform destroy` reports success even when a resource
fails to delete cleanly (a security group still referenced by an ENI, an
S3 bucket that wasn't empty, a CloudWatch alarm orphaned from a deleted
state file). Those leftovers keep billing quietly until someone notices
the AWS invoice. This script re-checks AWS directly, by tag, after a
destroy — independent of what Terraform's own state file believes.

Usage:
    python scripts/verify_teardown.py --project ojong-data-platform --region eu-west-3

Exit code 0  -> no leftover resources found, teardown is clean.
Exit code 1  -> leftover resources found; they are listed with their IDs.
"""
import argparse
import logging
import sys

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger("verify_teardown")
logging.basicConfig(level=logging.INFO, format="%(levelname)s:%(name)s:%(message)s")

TAG_KEY = "Project"


def _tag_filter(project: str) -> list:
    return [{"Name": f"tag:{TAG_KEY}", "Values": [project]}]


def find_leftover_ec2_instances(ec2_client, project: str) -> list:
    """Return running/stopped instances still tagged with this project."""
    try:
        resp = ec2_client.describe_instances(
            Filters=_tag_filter(project) + [
                {"Name": "instance-state-name", "Values": ["running", "stopped", "pending", "stopping"]}
            ]
        )
    except ClientError as e:
        logger.error("Failed to query EC2 instances: %s", e)
        raise
    instances = [
        inst["InstanceId"]
        for res in resp.get("Reservations", [])
        for inst in res.get("Instances", [])
    ]
    if instances:
        logger.error("Leftover EC2 instance(s): %s", instances)
    return instances


def find_leftover_security_groups(ec2_client, project: str) -> list:
    """Return security groups still tagged with this project (excluding 'default')."""
    try:
        resp = ec2_client.describe_security_groups(Filters=_tag_filter(project))
    except ClientError as e:
        logger.error("Failed to query security groups: %s", e)
        raise
    groups = [
        sg["GroupId"] for sg in resp.get("SecurityGroups", [])
        if sg.get("GroupName") != "default"
    ]
    if groups:
        logger.error("Leftover security group(s): %s", groups)
    return groups


def find_leftover_volumes(ec2_client, project: str) -> list:
    """Return EBS volumes still tagged with this project (common orphan after instance termination)."""
    try:
        resp = ec2_client.describe_volumes(Filters=_tag_filter(project))
    except ClientError as e:
        logger.error("Failed to query EBS volumes: %s", e)
        raise
    volumes = [v["VolumeId"] for v in resp.get("Volumes", [])]
    if volumes:
        logger.error("Leftover EBS volume(s): %s", volumes)
    return volumes


def find_leftover_rds_instances(rds_client, project: str) -> list:
    """Return RDS instances still tagged with this project."""
    try:
        resp = rds_client.describe_db_instances()
    except ClientError as e:
        logger.error("Failed to query RDS instances: %s", e)
        raise
    leftover = []
    for db in resp.get("DBInstances", []):
        arn = db["DBInstanceArn"]
        try:
            tags = rds_client.list_tags_for_resource(ResourceName=arn).get("TagList", [])
        except ClientError as e:
            logger.error("Failed to fetch tags for %s: %s", arn, e)
            continue
        if any(t["Key"] == TAG_KEY and t["Value"] == project for t in tags):
            leftover.append(db["DBInstanceIdentifier"])
    if leftover:
        logger.error("Leftover RDS instance(s): %s", leftover)
    return leftover


def find_leftover_s3_buckets(s3_client, project: str) -> list:
    """Return S3 buckets still tagged with this project."""
    try:
        resp = s3_client.list_buckets()
    except ClientError as e:
        logger.error("Failed to list S3 buckets: %s", e)
        raise
    leftover = []
    for bucket in resp.get("Buckets", []):
        name = bucket["Name"]
        try:
            tagging = s3_client.get_bucket_tagging(Bucket=name)
            tags = tagging.get("TagSet", [])
        except ClientError as e:
            if e.response["Error"]["Code"] in ("NoSuchTagSet", "NoSuchBucket"):
                continue
            logger.error("Failed to fetch tags for bucket %s: %s", name, e)
            continue
        if any(t["Key"] == TAG_KEY and t["Value"] == project for t in tags):
            leftover.append(name)
    if leftover:
        logger.error("Leftover S3 bucket(s): %s", leftover)
    return leftover


def find_leftover_cloudwatch_alarms(cw_client, project: str) -> list:
    """Return CloudWatch alarms whose name is prefixed with the project name."""
    try:
        resp = cw_client.describe_alarms(AlarmNamePrefix=project)
    except ClientError as e:
        logger.error("Failed to query CloudWatch alarms: %s", e)
        raise
    alarms = [a["AlarmName"] for a in resp.get("MetricAlarms", [])]
    if alarms:
        logger.error("Leftover CloudWatch alarm(s): %s", alarms)
    return alarms


def find_leftover_sns_topics(sns_client, project: str) -> list:
    """Return SNS topics whose ARN contains the project name."""
    leftover = []
    paginator = sns_client.get_paginator("list_topics")
    try:
        for page in paginator.paginate():
            for topic in page.get("Topics", []):
                if project in topic["TopicArn"]:
                    leftover.append(topic["TopicArn"])
    except ClientError as e:
        logger.error("Failed to list SNS topics: %s", e)
        raise
    if leftover:
        logger.error("Leftover SNS topic(s): %s", leftover)
    return leftover


def verify_teardown(project: str, region: str) -> tuple[bool, dict]:
    """
    Run every leftover-resource check for the given project/region.

    Returns (clean, report) where clean is True only if every check
    found nothing, and report maps resource type -> list of leftover IDs.
    """
    session = boto3.Session(region_name=region)
    ec2 = session.client("ec2")
    rds = session.client("rds")
    s3 = session.client("s3")
    cw = session.client("cloudwatch")
    sns = session.client("sns")

    report = {
        "ec2_instances": find_leftover_ec2_instances(ec2, project),
        "security_groups": find_leftover_security_groups(ec2, project),
        "ebs_volumes": find_leftover_volumes(ec2, project),
        "rds_instances": find_leftover_rds_instances(rds, project),
        "s3_buckets": find_leftover_s3_buckets(s3, project),
        "cloudwatch_alarms": find_leftover_cloudwatch_alarms(cw, project),
        "sns_topics": find_leftover_sns_topics(sns, project),
    }

    clean = all(len(v) == 0 for v in report.values())
    if clean:
        logger.info("Teardown verified clean for project '%s' in %s — no leftover resources.", project, region)
    else:
        total = sum(len(v) for v in report.values())
        logger.error("Teardown incomplete for project '%s': %d leftover resource(s) found.", project, total)

    return clean, report


def main():
    parser = argparse.ArgumentParser(description="Verify that terraform destroy left no billable resources behind.")
    parser.add_argument("--project", required=True, help="Value of the 'Project' tag used across your Terraform modules.")
    parser.add_argument("--region", required=True, help="AWS region to check, e.g. eu-west-3.")
    args = parser.parse_args()

    clean, report = verify_teardown(args.project, args.region)

    for resource_type, leftovers in report.items():
        status = "OK" if not leftovers else f"{len(leftovers)} LEFTOVER"
        print(f"{resource_type:20s} {status}")

    sys.exit(0 if clean else 1)


if __name__ == "__main__":
    main()