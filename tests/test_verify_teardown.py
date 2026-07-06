"""
Unit tests for verify_teardown.py.

boto3 clients are mocked throughout — these tests never touch real AWS.
Each check function is tested independently (clean case + leftover case),
and verify_teardown() itself is tested to confirm it aggregates every
check correctly and reports which resource types are dirty.
"""
import sys
import os
from unittest.mock import MagicMock, patch

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'scripts'))

from verify_teardown import (
    find_leftover_ec2_instances,
    find_leftover_security_groups,
    find_leftover_volumes,
    find_leftover_rds_instances,
    find_leftover_s3_buckets,
    find_leftover_cloudwatch_alarms,
    find_leftover_sns_topics,
    verify_teardown,
)

PROJECT = "weather-data-platform"


# ── EC2 instances ──────────────────────────────────────────────────────

def test_find_leftover_ec2_instances_returns_empty_when_none_tagged():
    ec2 = MagicMock()
    ec2.describe_instances.return_value = {"Reservations": []}
    assert find_leftover_ec2_instances(ec2, PROJECT) == []


def test_find_leftover_ec2_instances_returns_ids_when_present():
    ec2 = MagicMock()
    ec2.describe_instances.return_value = {
        "Reservations": [
            {"Instances": [{"InstanceId": "i-abc123"}, {"InstanceId": "i-def456"}]}
        ]
    }
    result = find_leftover_ec2_instances(ec2, PROJECT)
    assert result == ["i-abc123", "i-def456"]


# ── Security groups ─────────────────────────────────────────────────────

def test_find_leftover_security_groups_excludes_default():
    ec2 = MagicMock()
    ec2.describe_security_groups.return_value = {
        "SecurityGroups": [
            {"GroupId": "sg-111", "GroupName": "default"},
            {"GroupId": "sg-222", "GroupName": "weather-app-sg"},
        ]
    }
    result = find_leftover_security_groups(ec2, PROJECT)
    assert result == ["sg-222"]


def test_find_leftover_security_groups_returns_empty_when_none():
    ec2 = MagicMock()
    ec2.describe_security_groups.return_value = {"SecurityGroups": []}
    assert find_leftover_security_groups(ec2, PROJECT) == []


# ── EBS volumes ─────────────────────────────────────────────────────────

def test_find_leftover_volumes_returns_ids():
    ec2 = MagicMock()
    ec2.describe_volumes.return_value = {"Volumes": [{"VolumeId": "vol-999"}]}
    assert find_leftover_volumes(ec2, PROJECT) == ["vol-999"]


def test_find_leftover_volumes_returns_empty_when_none():
    ec2 = MagicMock()
    ec2.describe_volumes.return_value = {"Volumes": []}
    assert find_leftover_volumes(ec2, PROJECT) == []


# ── RDS instances ────────────────────────────────────────────────────────

def test_find_leftover_rds_instances_filters_by_tag():
    rds = MagicMock()
    rds.describe_db_instances.return_value = {
        "DBInstances": [
            {"DBInstanceIdentifier": "db-tagged", "DBInstanceArn": "arn:aws:rds:db-tagged"},
            {"DBInstanceIdentifier": "db-other", "DBInstanceArn": "arn:aws:rds:db-other"},
        ]
    }

    def fake_tags(ResourceName):
        if ResourceName == "arn:aws:rds:db-tagged":
            return {"TagList": [{"Key": "Project", "Value": PROJECT}]}
        return {"TagList": [{"Key": "Project", "Value": "some-other-project"}]}

    rds.list_tags_for_resource.side_effect = fake_tags
    result = find_leftover_rds_instances(rds, PROJECT)
    assert result == ["db-tagged"]


def test_find_leftover_rds_instances_returns_empty_when_none():
    rds = MagicMock()
    rds.describe_db_instances.return_value = {"DBInstances": []}
    assert find_leftover_rds_instances(rds, PROJECT) == []


# ── S3 buckets ───────────────────────────────────────────────────────────

def test_find_leftover_s3_buckets_filters_by_tag():
    s3 = MagicMock()
    s3.list_buckets.return_value = {
        "Buckets": [{"Name": "weather-lake-tagged"}, {"Name": "unrelated-bucket"}]
    }

    def fake_tagging(Bucket):
        if Bucket == "weather-lake-tagged":
            return {"TagSet": [{"Key": "Project", "Value": PROJECT}]}
        return {"TagSet": [{"Key": "Project", "Value": "other"}]}

    s3.get_bucket_tagging.side_effect = fake_tagging
    result = find_leftover_s3_buckets(s3, PROJECT)
    assert result == ["weather-lake-tagged"]


def test_find_leftover_s3_buckets_skips_buckets_with_no_tags():
    from botocore.exceptions import ClientError
    s3 = MagicMock()
    s3.list_buckets.return_value = {"Buckets": [{"Name": "untagged-bucket"}]}
    s3.get_bucket_tagging.side_effect = ClientError(
        {"Error": {"Code": "NoSuchTagSet", "Message": "no tags"}}, "GetBucketTagging"
    )
    assert find_leftover_s3_buckets(s3, PROJECT) == []


# ── CloudWatch alarms ────────────────────────────────────────────────────

def test_find_leftover_cloudwatch_alarms_returns_names():
    cw = MagicMock()
    cw.describe_alarms.return_value = {
        "MetricAlarms": [{"AlarmName": f"{PROJECT}-cpu-high"}]
    }
    assert find_leftover_cloudwatch_alarms(cw, PROJECT) == [f"{PROJECT}-cpu-high"]


def test_find_leftover_cloudwatch_alarms_returns_empty_when_none():
    cw = MagicMock()
    cw.describe_alarms.return_value = {"MetricAlarms": []}
    assert find_leftover_cloudwatch_alarms(cw, PROJECT) == []


# ── SNS topics ───────────────────────────────────────────────────────────

def test_find_leftover_sns_topics_matches_project_in_arn():
    sns = MagicMock()
    paginator = MagicMock()
    paginator.paginate.return_value = [
        {"Topics": [{"TopicArn": f"arn:aws:sns:eu-west-3:123:{PROJECT}-alerts"}]}
    ]
    sns.get_paginator.return_value = paginator
    result = find_leftover_sns_topics(sns, PROJECT)
    assert result == [f"arn:aws:sns:eu-west-3:123:{PROJECT}-alerts"]


def test_find_leftover_sns_topics_returns_empty_when_none():
    sns = MagicMock()
    paginator = MagicMock()
    paginator.paginate.return_value = [{"Topics": []}]
    sns.get_paginator.return_value = paginator
    assert find_leftover_sns_topics(sns, PROJECT) == []


# ── verify_teardown (aggregated) ────────────────────────────────────────

@patch("verify_teardown.boto3.Session")
def test_verify_teardown_reports_clean_when_nothing_leftover(mock_session_cls):
    mock_session = MagicMock()
    mock_session_cls.return_value = mock_session

    ec2 = MagicMock()
    ec2.describe_instances.return_value = {"Reservations": []}
    ec2.describe_security_groups.return_value = {"SecurityGroups": []}
    ec2.describe_volumes.return_value = {"Volumes": []}

    rds = MagicMock()
    rds.describe_db_instances.return_value = {"DBInstances": []}

    s3 = MagicMock()
    s3.list_buckets.return_value = {"Buckets": []}

    cw = MagicMock()
    cw.describe_alarms.return_value = {"MetricAlarms": []}

    sns = MagicMock()
    paginator = MagicMock()
    paginator.paginate.return_value = [{"Topics": []}]
    sns.get_paginator.return_value = paginator

    def fake_client(service_name):
        return {"ec2": ec2, "rds": rds, "s3": s3, "cloudwatch": cw, "sns": sns}[service_name]

    mock_session.client.side_effect = fake_client

    clean, report = verify_teardown(PROJECT, "eu-west-3")

    assert clean is True
    assert all(v == [] for v in report.values())


@patch("verify_teardown.boto3.Session")
def test_verify_teardown_reports_dirty_when_leftovers_exist(mock_session_cls):
    mock_session = MagicMock()
    mock_session_cls.return_value = mock_session

    ec2 = MagicMock()
    ec2.describe_instances.return_value = {
        "Reservations": [{"Instances": [{"InstanceId": "i-leftover"}]}]
    }
    ec2.describe_security_groups.return_value = {"SecurityGroups": []}
    ec2.describe_volumes.return_value = {"Volumes": []}

    rds = MagicMock()
    rds.describe_db_instances.return_value = {"DBInstances": []}

    s3 = MagicMock()
    s3.list_buckets.return_value = {"Buckets": []}

    cw = MagicMock()
    cw.describe_alarms.return_value = {"MetricAlarms": []}

    sns = MagicMock()
    paginator = MagicMock()
    paginator.paginate.return_value = [{"Topics": []}]
    sns.get_paginator.return_value = paginator

    def fake_client(service_name):
        return {"ec2": ec2, "rds": rds, "s3": s3, "cloudwatch": cw, "sns": sns}[service_name]

    mock_session.client.side_effect = fake_client

    clean, report = verify_teardown(PROJECT, "eu-west-3")

    assert clean is False
    assert report["ec2_instances"] == ["i-leftover"]