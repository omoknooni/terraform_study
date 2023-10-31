#!/bin/bash
echo "#### Install CW Agent ####"
curl -O https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E amazon-cloudwatch-agent.deb
sudo systemctl enable amazon-cloudwatch-agent

echo "#### Configure CW Agent ####"
sudo touch /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
sudo cat << EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
    "agent": {

}

# write cloudwatch agent configure file to collect ssh log
{
    "agent" : {
        "metrics_collection_interval" : 60,
        "run_as_user" : "root"
    }
    "logs" : {
        "logs_collected" : {
            "files" : {
                "collect_list" : [
                    {
                        "file_path" : "/var/log/auth.log",
                        "log_group_name" : "cwagent_ssh_log",
                        "log_stream_name" : "{instance_id}",
                        "retention_in_days" : 30
                    }
                ]
            }
        }
    },
    "metrics" : {
        "aggregation_dimensions" : [
            [
                "InstanceId"
            ]
        ],
        "append_dimensions" : {
            "AutoScalingGroupName" : "\${aws:AutoScalingGroupName}",
            "ImageId" : "\${aws:ImageId}",
            "InstanceId" : "\${aws:InstanceId}",
            "InstanceType" : "\${aws:InstanceType}"
        },
        "metrics_collected" : {
            "disk" : {
                "measurement" : [
                    "disk_used_percent"
                ],
                "metrics_collection_interval" : 60,
                "resources" : [
                    "*"
                ]
            },
            "mem" : {
                "measurement" : [
                    "mem_used_percent"
                ],
                "metrics_collection_interval" : 60
            }
        }
    }
}
EOF

echo "#### Start CW Agent ####"
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
sudo systemctl start amazon-cloudwatch-agent