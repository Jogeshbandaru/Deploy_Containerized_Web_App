resource "aws_sns_topic" "alarm_notifications" {
  name = "ecs-alarm-notifications"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alarm_notifications.arn
  protocol  = "email"
  endpoint  = "jogesh.bandaru@gmail.com"  # Change to your email
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-ecs"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace          = "AWS/ECS"
  period             = 60
  statistic          = "Average"
  threshold          = 80
  alarm_description  = "Alarm when ECS CPU exceeds 80%"
  alarm_actions      = [aws_sns_topic.alarm_notifications.arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.my_cluster.name
    ServiceName = aws_ecs_service.web_service.name
  }
}

resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name          = "high-memory-ecs"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace          = "AWS/ECS"
  period             = 60
  statistic          = "Average"
  threshold          = 80
  alarm_description  = "Alarm when ECS Memory exceeds 80%"
  alarm_actions      = [aws_sns_topic.alarm_notifications.arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.my_cluster.name
    ServiceName = aws_ecs_service.web_service.name
  }
}

resource "aws_cloudwatch_dashboard" "ecs_dashboard" {
  dashboard_name = "ECSMonitoringDashboard"
  dashboard_body = <<EOF
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/ECS", "CPUUtilization", "ClusterName", "${aws_ecs_cluster.my_cluster.name}", "ServiceName", "${aws_ecs_service.web_service.name}" ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "title": "ECS CPU Utilization"
      }
    },
    {
      "type": "metric",
      "x": 6,
      "y": 0,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/ECS", "MemoryUtilization", "ClusterName", "${aws_ecs_cluster.my_cluster.name}", "ServiceName", "${aws_ecs_service.web_service.name}" ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "title": "ECS Memory Utilization"
      }
    }
  ]
}
EOF
}
