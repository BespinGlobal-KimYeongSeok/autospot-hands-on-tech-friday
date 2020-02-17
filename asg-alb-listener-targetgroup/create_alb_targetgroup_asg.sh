#!/usr/local/bin/bash

####################################
# Declare functions and variables ##
####################################

## 리전별 아마존 리눅스 AMI 초기화
declare_amazon_linux_ami_hash(){
    
    declare -A -g alami_arr
    alami_arr[useast1]="ami-09d069a04349dc3cb"
    alami_arr[useast2]="ami-0d542ef84ec55d71c"
    alami_arr[uswest1]="ami-04bc3da8f14823e88"
    alami_arr[uswest2]="ami-0e8c04af2729ff1bb"
    alami_arr[apeast1]="ami-7ab4f00b" 
    alami_arr[apsouth1]="ami-09d069a04349dc3cb"
    alami_arr[apnortheast2]="ami-0e4a253fb5f082688"
    alami_arr[apsoutheast1]="ami-0d9233e8ce73df7b2"
    alami_arr[apsoutheast2]="ami-0c91f97cadcc8499e"
    alami_arr[apnortheast1]="ami-079e6fb1e856e80c1"
    alami_arr[cacentral1]=" ami-003a0ba7ea76b2785"
    alami_arr[eucentral1]="ami-0ba441bdd9e494102"
    alami_arr[euwest1]="ami-071f4ce599deff521"
    alami_arr[euwest2]="ami-0e49551fc78560451"
    alami_arr[euwest3]="ami-0ec1d48c59dda554a"
    alami_arr[eunorth1]="ami-0f1d8c8ad70ce9c62"
    alami_arr[mesouth1]="ami-0f9dd846ebb1d7a81" 
    alami_arr[saeast1]="ami-0b7a1f602d34f142f" 

}

## 리전 정보 가져오기
get_region_array(){
    local region_arr=( $(aws ec2 describe-regions | jq -r '.Regions[].RegionName') )
    if [ $? -ne 0 ]; then
        error_exit $fetch_default_regions_error
    else
        default_region_arr=${region_arr[@]}
    fi
}

## 가용영역 정보 가져오기
get_azs_array(){
    local azs_arr=( $(aws ec2 describe-availability-zones --region $region_code --filters Name=state,Values=available | jq -r '.AvailabilityZones[].ZoneName') )
    if [ $? -ne 0 ]; then
        error_exit $fetch_default_azs_error
    else
        availability_zones_arr=( ${azs_arr[@]} )
    fi
}

## 글로벌 변수 초기화
init_variables(){
    
    ##정적 초기화
    declare_amazon_linux_ami_hash
    default_region_arr=()
    default_region_code=$(aws configure get region)
    region_code=$default_region_code
    default_vpc_id=""
    default_alb_name="default-application-loadbalancer"
    default_target_group_name="default-target-group"
    default_key_name="default-key-pair"
    created_key_name=""
    default_launch_configuration_name="default-launch-configuration"
    default_auto_scaling_group_name="default-autoscaling-group"
    prog_name=$(basename $0)
    
    
    subnet_choices=()
    target_group_arn=""

    ##동적 초기화
    get_region_array
    availability_zones_arr=()
    availability_zones_choices=()
    
}

## 에러코드 초기화
init_errorcodes(){

    attach_lb_tg_error="대상그룹과 오토스케일링 그룹을 연결하는데 실패하였습니다."
    fetch_default_vpc_error="기본 VPC 정보를 가져오는 데 실패하였습니다."
    fetch_default_regions_error="리전 정보를 가져오는 데 실패하였습니다."
    fetch_default_azs_error="리전 정보를 가져오는 데 실패하였습니다."
    create_target_group_error="대상그룹을 생성하는데 실패하였습니다."
}


## 해당 리전에 기본 VPC 값 가져오기
get_default_vpc_from_region () {
    echo "-------------------------------------------------------------------------------------"
    echo "기본 VPC 정보를 가져옵니다."
    local result=$(aws ec2 describe-vpcs --region $region_code --filters Name=isDefault,Values=true  | jq -r '.Vpcs[].VpcId')     
    local return_code=$?
    if [ $return_code -eq 0 ]; then
        echo "사용하실 리전의 기본 Virtual Private Cloud 의 ID는 ${result}입니다"
        default_vpc_id=$result
    else 
        error_exit $fetch_default_vpc_error
    fi
    echo "-------------------------------------------------------------------------------------"
}

multi_select_subnets_from_array(){
    
    
    menu() {
        echo "-------------------------------------------------------------------------------------"
        echo "해당 리전의 서브넷 목록입니다 :"
        for i in ${!subnets_arr[@]}; do
            printf "%3d%s) %s\n" $((i+1)) "${choices[i]:- }" "${subnets_arr[i]}"
        done
        [[ "$msg" ]] && echo "$msg"; :
    }
    
    prompt="로드발란서에서 사용할 서브넷의 번호를 입력해주세요 (두번 선택시 미선택됩니다, ENTER 를 누르면 종료됩니다): "
    while menu && read -rp "$prompt" num && [[ "$num" ]]; do
        [[ "$num" != *[![:digit:]]* ]] &&
        (( num > 0 && num <= ${#subnets_arr[@]} )) ||
        { msg="Invalid option: $num"; continue; }
        ((num--)); msg="${subnets_arr[num]} was ${choices[num]:+un}checked"
        subnet_choices[num]=${subnets_arr[num]}
        [[ "${choices[num]}" ]] && choices[num]="" || choices[num]="+"
    done
    
    printf "선택하신 항목은"; msg=" 없습니다."
    for i in ${!subnets_arr[@]}; do
        [[ "${choices[i]}" ]] && { printf " %s" "${subnets_arr[i]}"; msg=""; }
    done
    echo "$msg"
}

multi_select_azs_from_array(){
    get_azs_array
    menu() {
        for i in ${!availability_zones_arr[@]}; do
            printf "%3d%s) %s\n" $((i+1)) "${choice_indexs[i]:- }" "${availability_zones_arr[i]}"
        done
        [[ "$msg" ]] && echo "$msg"; :
    }
    
    prompt="오토스케일링그룹에 사용할 가용존의 번호를 입력해주세요 (두번 선택시 미선택됩니다, ENTER 를 누르면 종료됩니다): "
    while menu && read -rp "$prompt" num && [[ "$num" ]]; do
        [[ "$num" != *[![:digit:]]* ]] &&
        (( num > 0 && num <= ${#availability_zones_arr[@]} )) ||
        { msg="Invalid option: $num"; continue; }
        ((num--)); msg="${availability_zones_arr[num]} was ${choice_indexs[num]:+un}checked"
        availability_zones_choices[num]=${availability_zones_arr[num]}
        [[ "${choice_indexs[num]}" ]] && choice_indexs[num]="" || choice_indexs[num]="+"
    done
    
    printf "선택하신 항목은"; msg=" 없습니다."
    for i in ${!availability_zones_arr[@]}; do
        [[ "${choice_indexs[i]}" ]] && { printf " %s" "${availability_zones_arr[i]}"; msg=""; }
    done
    echo "$msg"
    echo $availability_zones_choices
}

select_subnets_or_input(){
    subnets_arr=( $(aws ec2 describe-subnets --region $region_code --filters Name=vpc-id,Values=${default_vpc_id} | jq -r '.Subnets[].SubnetId') )
    multi_select_subnets_from_array 
    for subnet in ${subnet_choices[@]};
    do 
        echo $subnet 
    done
    
}

## 기본 리전정보 가져오기
get_default_region_or_input(){
    echo "-------------------------------------------------------------------------------------"
    echo "사용할 리전을 선택해주세요."
    select region_name in ${default_region_arr[@]} exit
    do
        case $region_name in 
        exit) echo "${default_region_code}을 기본으로 사용합니다."
        break
        ;;
        *) echo "${region_name}을 기본 리전으로 사용합니다."
        region_code=$region_name
        break
        ;; 
        esac
    done
    region_code_key=${region_code//[-]/''}
    default_ami=${alami_arr["$region_code_key"]}
    echo "-------------------------------------------------------------------------------------"
}

get_default_albname_or_input(){
    read -rp "생성할 어플리케이션 로드발란서의 이름을 입력해 주세요(미입력시 기본값은 ${default_alb_name} 입니다) : " alb_name
    if [ -z "$alb_name" ]; then
        alb_name=${alb_name:-$default_alb_name}
        echo "기본값 이름을 사용합니다: $alb_name"
    fi
}


select_security_groups_or_input(){

    default_security_group=$(aws ec2 describe-security-groups --region $region_code --group-names default --filters Name=vpc-id,Values=vpc-3c450346 | jq -r '.SecurityGroups[].GroupId')
    echo "기본 Security Group을 사용합니다 : $default_security_group"
    
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
    echo "-------------------------------------------------------------------------------------"
    read -p "대상그룹 이름을 입력해 주세요.(미입력시 기본값은 ${default_target_group_name}입니다) :" target_group_name
    target_group_name=${target_group_name:-$default_target_group_name}
    echo "대상그룹이름: $target_group_name"
    
    local script="aws elbv2 create-target-group --region $region_code --name $target_group_name --protocol HTTP --port 80 --vpc-id $default_vpc_id | jq -r '.TargetGroups[].TargetGroupArn'"
    target_group_arn=$(eval $script)    
    if [ $? -ne 0 ]; then
        error_exit $create_target_group_error
    fi
    echo "-------------------------------------------------------------------------------------"
}

create_listener_with_alb_targetgroup(){
    echo "-------------------------------------------------------------------------------------"
    echo "생성된 어플리케이션 로드 발란서의 HTTP:80 Request 를 생성한 대상그룹으로 포워딩할 리스너를 생성합니다."
    local script="aws elbv2 create-listener --load-balancer-arn $alb_arn --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$target_group_arn --region $region_code"
    eval $script
    if [ $? -ne 0 ]; then
        error_exit "Failed to create a listener"
    fi
    echo "-------------------------------------------------------------------------------------"
}

create_a_new_key_pair(){
    echo "-------------------------------------------------------------------------------------"
    read -p "생성할 키페어 이름을 입력하세요 : " key_name
    key_name=${key_name:-$default_key_name}
    aws ec2 create-key-pair --key-name $key_name --region $region_code | jq -r ".KeyMaterial" > ~/.ssh/${key_name}.pem
    echo "~/.ssh/ 디렉토리에 키페어가 저장되었습니다"
    ls -al ~/.ssh/${key_name}.pem
    sleep 5
    echo "-------------------------------------------------------------------------------------"
    aws ec2 wait key-pair-exists --key-names $key_name --region $region_code
    echo $?
    created_key_name=$key_name
    echo "-------------------------------------------------------------------------------------"
}

select_keypair_if_exits_or_create(){
    keypair_array=($(aws ec2 describe-key-pairs --region $region_code | jq -r ".KeyPairs[].KeyName"))
    keypair_array_length=${#keypair_array[@]}
    if [ $keypair_array_length -eq 0 ]; then
        echo "${region_code} 리전에 생성된 키페어가 없습니다. 새로운 키페어를 생성합니다."
        #Creating a new key pair
        create_a_new_key_pair
        echo "키페어가 성공적으로 생성되었습니다."
    else
        select key_name in ${keypair_array[@]}
        do
        echo "${key_name}를 키페어로 선택하였습니다."
        break
        done
    fi
}

create_launch_configuration(){
    echo "-------------------------------------------------------------------------------------"
    read -p "생성할 Launch Configuration 이름을 입력하세요(미입력시 기본값은 ${default_launch_configuration_name}입니다) : " launch_configuration_name
    launch_configuration_name=${launch_configuration_name:-$default_launch_configuration_name}

    echo "Launch Configuration 에 사용할 Key Pair 를 선택하세요."
    #키페어 확인 후 선택 혹은 생성
    select_keypair_if_exits_or_create

    aws autoscaling create-launch-configuration \
  --launch-configuration-name $launch_configuration_name \
  --image-id $default_ami \
  --key-name $key_name \
  --instance-type m4.large --user-data file://instance-setup.sh \
  --region $region_code
  echo "-------------------------------------------------------------------------------------"
}

create_auto_scaling_group(){

    #1
    create_launch_configuration

    #2
    multi_select_azs_from_array

    read -p "생성할 AutoScalingGroup 이름을 입력하세요 (미입력시 기본값은 ${default_auto_scaling_group_name}입니다) : " auto_scaling_group_name
    auto_scaling_group_name=${auto_scaling_group_name:-$default_auto_scaling_group_name}

    aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name $auto_scaling_group_name \
  --launch-configuration-name $launch_configuration_name \
  --min-size 1 \
  --max-size 1 \
  --desired-capacity 1 \
  --availability-zones ${availability_zones_choices[@]} \
  --region $region_code

}

attach_loadblanacer_target_group(){

    aws autoscaling attach-load-balancer-target-groups \
    --auto-scaling-group-name $auto_scaling_group_name \
    --target-group-arns $target_group_arn \
    --region $region_code

    if [ $? -ne 0 ]; then
        error_exit $attach_lb_tg_error
    fi

}


error_exit(){
    echo "${prog_name}: ${1:-"Unknown Error"}" 1>&2
}

##############
# Main Start #
##############

#1
init_variables

#2
get_default_region_or_input


#3
get_default_vpc_from_region

#4
create_application_load_balancer

#5
create_auto_scaling_group

#6
attach_loadblanacer_target_group

#7
if [ $? -eq 0 ]; then
    echo "Hands-on을 위한 실습자원 생성을 완료하였습니다."
else 
    echo "Hands-on을 위한 실습자원 생성을 실패하였습니다."
    echo "생성한 자원을 삭제합니다."
    #1 로드 발란서 삭제
    aws elbv2 delete-load-balancer --region $region_code --load-balancer-arn $alb_arn

    #2 타켓그룹 삭제
    aws elbv2 delete-target-group --region $region_code --target-group-arn $target_group_arn

    #3 오토스케일링 그룹 삭제
    aws autoscaling delete-auto-scaling-group --region $region_code --auto-scaling-group-name $auto_scaling_group_name
    
    #4 오토스케일링 그룹 설정 삭제
    aws autoscaling delete-launch-configuration --region $region_code --launch-configuration-name $launch_configuration_name

    #5 키페어삭제
    aws ec2 delete-key-pair --region $region_code --key-name $created_key_name

fi