aws autoscaling create-launch-configuration --launch-configuration-name my-launch-config \
  --image-id ami-01e24be29428c15b2 --instance-type t2.micro --associate-public-ip-address \
  --security-groups sg-eb2af88e
  --region us-east-1