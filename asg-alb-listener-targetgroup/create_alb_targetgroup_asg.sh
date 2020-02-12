#!/bin/bash

####################################
# Declare functions and variables ##
####################################


declare_amazon_linux_ami_hash(){

    declare -a alami_arr
    alami_arr['us_east_1']="ami-09d069a04349dc3cb"
    alami_arr["us_east_2"]="ami-0d542ef84ec55d71c"
    alami_arr["us_west_1"]="ami-04bc3da8f14823e88"
    alami_arr["us_west_2"]="ami-01460aa81365561fe"
    # alami_arr["ap-east-1"]="ami-04bc3da8f14823e88" HongKong being prepared
    alami_arr["ap_south_1"]="ami-09d069a04349dc3cb"
    alami_arr["ap_northeast_2"]="ami-0e4a253fb5f082688"
    alami_arr["ap_southeast_1"]="ami-0d9233e8ce73df7b2"
    alami_arr["ap_southeast_2"]="ami-0c91f97cadcc8499e"
    alami_arr["ap_northeast_1"]="ami-079e6fb1e856e80c1"
    alami_arr["ca_central_1"]=" ami-003a0ba7ea76b2785"
    alami_arr["eu_central_1"]="ami-0ab838eeee7f316eb"
    alami_arr["eu_west_1"]="ami-071f4ce599deff521"
    alami_arr["eu_west_2"]="ami-0e49551fc78560451"
    alami_arr["eu_west_3"]="ami-0ec1d48c59dda554a"
    alami_arr["eu_north_1"]="ami-0f1d8c8ad70ce9c62"
    # alami_arr["me-south-1"]="ami-09d069a04349dc3cb" Bahrain being prepared
    alami_arr["sa_east_1"]="ami-0b7a1f602d34f142f" 

}
init_variables(){
    declare_amazon_linux_ami_hash
    prog_name=$(basename $0)
    default_region_code=$(aws configure get region)
    region_code_hyphen=${default_region_code//[-]/_}
    default_vpc_id=""
    subnet_choices=()
    default_alb_name="default-application-loadbalancer"
    default_target_group_name="default-target-group"
    target_group_arn=""

    default_key_name="default-key-pair"
    default_ami=$alami_arr[$region_code_hyphen]
    default_auto_scaling_group_name="default-autoscaling-group"
    default_launch_configuration_name="default-launch-configuration"
    availability_zones_arr=( $(aws ec2 describe-availability-zones --filters Name=state,Values=available | jq -r '.AvailabilityZones[].ZoneName') )
    availability_zones_choices=()
}
init_errorcodes(){

    attach_lb_tg_error="Failed To Attach Target Group to AutoScalingGroup"
}



get_default_vpc_from_region () {
    echo "getting default vpc information from the default region"
    local result=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true  | jq -r '.Vpcs[].VpcId')     
    local return_code=$?
    if [ $return_code -eq 0 ]; then
        echo "Your Default VPC ID: $result"
        default_vpc_id=$result
    else 
        echo "Can't fetch your default VPC"
        exit 1
    fi
}

multi_select_subnets_from_array(){
    
    echo "options: $subnets_arr"
    menu() {
        echo "Avaliable options:"
        for i in ${!subnets_arr[@]}; do
            printf "%3d%s) %s\n" $((i+1)) "${choices[i]:- }" "${subnets_arr[i]}"
        done
        [[ "$msg" ]] && echo "$msg"; :
    }
    
    prompt="Check an option (again to uncheck, ENTER when done): "
    while menu && read -rp "$prompt" num && [[ "$num" ]]; do
        [[ "$num" != *[![:digit:]]* ]] &&
        (( num > 0 && num <= ${#subnets_arr[@]} )) ||
        { msg="Invalid option: $num"; continue; }
        ((num--)); msg="${subnets_arr[num]} was ${choices[num]:+un}checked"
        subnet_choices[num]=${subnets_arr[num]}
        [[ "${choices[num]}" ]] && choices[num]="" || choices[num]="+"
    done
    
    printf "You selected"; msg=" nothing"
    for i in ${!subnets_arr[@]}; do
        [[ "${choices[i]}" ]] && { printf " %s" "${subnets_arr[i]}"; msg=""; }
    done
    echo "$msg"
    echo $subnet_choices
}

multi_select_azs_from_array(){
    
    echo "options: $availability_zones_arr"
    menu() {
        echo "Avaliable options:"
        for i in ${!availability_zones_arr[@]}; do
            printf "%3d%s) %s\n" $((i+1)) "${choices[i]:- }" "${availability_zones_arr[i]}"
        done
        [[ "$msg" ]] && echo "$msg"; :
    }
    
    prompt="Check an option (again to uncheck, ENTER when done): "
    while menu && read -rp "$prompt" num && [[ "$num" ]]; do
        [[ "$num" != *[![:digit:]]* ]] &&
        (( num > 0 && num <= ${#availability_zones_arr[@]} )) ||
        { msg="Invalid option: $num"; continue; }
        ((num--)); msg="${availability_zones_arr[num]} was ${choices[num]:+un}checked"
        availability_zones_choices[num]=${availability_zones_arr[num]}
        [[ "${choices[num]}" ]] && choices[num]="" || choices[num]="+"
    done
    
    printf "You selected"; msg=" nothing"
    for i in ${!availability_zones_arr[@]}; do
        [[ "${choices[i]}" ]] && { printf " %s" "${availability_zones_arr[i]}"; msg=""; }
    done
    echo "$msg"
    echo $availability_zones_choices
}

select_subnets_or_input(){
    subnets_arr=( $(aws ec2 describe-subnets --filters Name=vpc-id,Values=vpc-3c450346 | jq -r '.Subnets[].SubnetId') )
    multi_select_subnets_from_array 
    for subnet in ${subnet_choices[@]};
    do 
        echo $subnet 
    done
    
}

get_default_region_or_input(){
    
    read -rp '리전코드를 입력해 주세요.그냥 Enter 시 AWS Configure에 설정된 값으로 진행합니다: ' region_code
    if [ -z "$region_code" ]; then
        region_code=${region_code:-$default_region_code}
        echo "디폴트 리전: $region_code"
    fi
}

get_default_albname_or_input(){
    read -rp "ALB 이름을 입력해 주세요.: " alb_name
    echo $alb_name
    if [ -z "$alb_name" ]; then
        alb_name=${alb_name:-$default_alb_name}
        echo "디폴트 이름을 사용합니다: $alb_name"
    fi
}


select_security_groups_or_input(){

    default_security_group=$(aws ec2 describe-security-groups --group-names default --filters Name=vpc-id,Values=vpc-3c450346 | jq -r '.SecurityGroups[].GroupId')
    echo "디폴트 Security Group을 사용합니다: $default_security_group"
    
}



create_application_load_balancer(){

    #1
    get_default_albname_or_input

    #2
    select_subnets_or_input

    #3
    select_security_groups_or_input

    local script="aws elbv2 create-load-balancer --name $alb_name --subnets ${subnet_choices[@]} --security-groups $default_security_group --region $region_code | jq -r '.LoadBalancers[].LoadBalancerArn'"
    clb_response=$(eval $script)
    if [ $? -ne 0 ]; then
        error_exit "Application Load Balancer 생성에 실패하였습니다."
    else
        alb_arn=$clb_response     
        echo "Application Load Balancer 생성에 성공하였습니다."
    fi
    
    #4
    create_target_group

    #5
    create_listener_with_alb_targetgroup

}


create_target_group(){

    read -p "대상그룹 이름을 입력해 주세요.(Enter시 기본 값 사용):" target_group_name
    target_group_name=${target_group_name:-$default_target_group_name}
    echo "대상그룹이름: $target_group_name"
    
    local script="aws elbv2 create-target-group --name $target_group_name --protocol HTTP --port 80 --vpc-id $default_vpc_id | jq -r '.TargetGroups[].TargetGroupArn'"
    target_group_arn=$(eval $script)    
    if [ $? -ne 0 ]; then
        error_exit "Failed to create a target group"
    fi
    
}

create_listener_with_alb_targetgroup(){
    echo "생성된 어플리케이션 로드 발란서의 HTTP:80 Request 를 생성한 대상그룹으로 포워딩할 리스너를 생성합니다."
    local script="aws elbv2 create-listener --load-balancer-arn $alb_arn --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$target_group_arn --region $region_code"
    eval $script
    if [ $? -ne 0 ]; then
        error_exit "Failed to create a listener"
    fi
}

create_a_new_key_pair(){
    read -p "생성할 키페어 이름을 입력하세요 : " key_name
    key_name=${key_name:-$default_key_name}
    aws ec2 create-key-pair --key-name $key_name --region $default_region_code | jq -r ".KeyMaterial" > ~/.ssh/${key_name}.pem
    echo "Your key pair has been saved under ~/.ssh/ directory"
    ls -al ~/.ssh/${key_name}.pem
}

select_keypair_if_exits_or_create(){
    keypair_array=($(aws ec2 describe-key-pairs --region $default_region_code | jq -r ".KeyPairs[].KeyName"))
    keypair_array_length=${#keypair_array[@]}
    if [ $keypair_array_length -eq 0 ]; then
        echo "해당 리전에 생성된 키페어가 없습니다.: $default_region_code, 새로운 키페어를 생성합니다."
        #Creating a new key pair
        create_a_new_key_pair
        echo "키페어가 성공적으로 생성되었습니다."
    else
        select key_name in ${keypair_array[@]}
        do
        echo "You have chosen to use $key_name"
        break
        done
    fi
}

create_launch_configuration(){
    read -p "생성할 Launch Configuration 이름을 입력하세요 : " launch_configuration_name
    launch_configuration_name=${launch_configuration_name:-$default_launch_configuration_name}

    echo "Launch Configuration 에 사용할 Key Pair 를 선택하세요."
    #키페어 확인 후 선택 혹은 생성
    select_keypair_if_exits_or_create

    
    echo "AMI Check: $default_ami"

    aws autoscaling create-launch-configuration \
  --launch-configuration-name $launch_configuration_name \
  --image-id $default_ami \
  --key-name $key_name \
  --instance-type t1.micro --user-data file://instance-setup.sh 
}

create_auto_scaling_group(){

    #1
    create_launch_configuration

    read -p "생성할 AutoScalingGroup 이름을 입력하세요 : " auto_scaling_group_name
    auto_scaling_group_name=${auto_scaling_group_name:-$default_auto_scaling_group_name}

    aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name $auto_scaling_group_name \
  --launch-configuration-name $launch_configuration_name \
  --min-size 1 \
  --max-size 1 \
  --desired-capacity 1 \
  --availability-zones ${availability_zones_choices[@]}

}

attach_loadblanacer_target_group(){

    aws autoscaling attach-load-balancer-target-groups \
    --auto-scaling-group-name $auto_scaling_group_name \
    --target-group-arns $target_group_arn

    if [ $? -ne 0]; then
        error_exit $attach_lb_tg_error
    fi

}


error_exit(){
    echo "${prog_name}: ${1:-"Unknown Error"}" 1>&2
    if [ $alb_arn !="" ]; then
        echo "Deleteing ALB"
        aws elbv2 delete-load-balancer --load-balancer-arn $alb_arn
    fi
    if [ $target_group_arn !="" ]; then
        echo "Deleteing Target Group"
        aws elbv2 delete-target-group --target-group-arn $target_group_arn
    fi
    exit 1
}

##############
# Main Start #
##############

#Variable Init
init_variables


#1
get_default_region_or_input

#2
get_default_vpc_from_region

#3
create_application_load_balancer

#4
create_auto_scaling_group
