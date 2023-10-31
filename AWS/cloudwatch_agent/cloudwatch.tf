# Log group
resource "aws_cloudwatch_log_group" "cwagent_log_group" {
    name = "cwagent_ssh_log"
    retention_in_days = 0
}

# resource "aws_cloudwatch_log_subscription_filter" "cwagent_filter" {
#     log_group_name = aws_cloudwatch_log_group.cwagent_log_group.name
#     filter_pattern = ""
#     destination_arn = aws_instance.cloudwatchagent_demo.arn
#     role_arn = 
# }


# IAM
resource "aws_iam_role" "cw_log_role" {
    name = "cw_log_role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "ec2.amazonaws.com"
            }
        }]
    })
}

resource "aws_iam_role_policy_attachment" "cw_agent_role_attach" {
    policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    role = aws_iam_role.cw_log_role.name
}

resource "aws_iam_role_policy_attachment" "ssm_role_attach" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    role = aws_iam_role.cw_log_role.name
}