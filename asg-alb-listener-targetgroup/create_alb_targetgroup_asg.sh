#!/bin/bash

####################################
# Declare functions and variables ##
####################################
init_variables(){
    default_region_code=(`eval "aws configure get region"`)
    default_vpc_id=""
    subnet_choices=()
    default_alb_name="default-application-loadbalancer"
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

multi_select_from_array(){
    
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


select_subnets_or_input(){
    subnets_arr=( $(aws ec2 describe-subnets --filters Name=vpc-id,Values=vpc-3c450346 | jq -r '.Subnets[].SubnetId') )
    multi_select_from_array 
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

    echo $region_code
    echo ${subnet_choices[@]}
    SCRIPT="aws elbv2 create-load-balancer --name $alb_name --subnets ${subnet_choices[@]} --security-groups $default_security_group --region $region_code | jq -r '.LoadBalancers[].LoadBalancerArn'"

    clb_response=$(eval $SCRIPT)
    echo "response>>$clb_response"
    alb_arn=$clb_response 
    echo $alb_arn

    result=$?
    echo $result
}


create_target_group(){

    local VPC_ID="vpc-3c450346"
    vared -p "대상그룹을 생성할 VPC ID를 입력해 주세요 :" -c VPC_ID
    echo $VPC_ID
    vared -p "대상그룹 이름을 입력해 주세요.:" -c TARGET_GROUP
    echo $TARGET_GROUP
    SCRIPT="aws elbv2 create-target-group --name $TARGET_GROUP --protocol HTTP --port 80 --vpc-id $VPC_ID | jq -r '.TargetGroups[].TargetGroupArn'"
    echo "Script: $SCRIPT"
    target_group_arn=$(eval $SCRIPT)    
    local result=$?
}

create_listener_with_alb_targetgroup(){
    echo "생성된 어플리케이션 로드 발란서의 HTTP:80 Request 를 생성한 대상그룹으로 포워딩할 리스너를 생성합니다."
    SCRIPT="aws elbv2 create-listener --load-balancer-arn $alb_arn --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$target_group_arn --region $REGION_CODE"
    eval $SCRIPT
    local result=$?
    if [ $result -eq 0 ]; 
    then
        echo "리스너 등록에 성공하였습니다."
        exit 0        
    else
        exit 1
    fi
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
