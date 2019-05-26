"""
Very simple Lambda function to Stop/Start Instances depending on
targets declared in the environment variables of this function.

Updates:
  - 01 Oct. 2018: Adding support of suspend/resume for AGSs

"""

import boto3
import json
import logging
import os
from typing import List, Dict, AnyStr


LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)


class NoTargetFoundError(Exception):
    """
    Generic exception raised when no suitable instances found.
    """
    pass


def get_elligible_instances(instances, desired_status: str) -> List[AnyStr]:
    """
    From a collection of instances extract only the good ones.
    A good instance is :
     - Instance with the right status (running or stopped) depending on
       what you want to do
     - Instance with EBS root device only (to avoid loss of data on instance
       store backed instances)
    
    :param instances: Collection of instance objects
    :param desired_status: The status we are looking for 
    :returns: list of InstanceIds [(str)]
    :raises NoTargetFoundError: If no instance match
    """
    elligible_instances_ids = []
    nonsuitable_states = ['terminated', 'pending', 'stopping', 'shutting-down', 'rebooting']

    LOGGER.info('Beginning security checks')
    for instance in instances:
        if instance.state['Name'] in nonsuitable_states:
            LOGGER.warning(f'Skipping instance {instance.id}'
                           f'(non suitable state: {instance.state["Name"]})')
            continue
        
        if instance.state['Name'] == desired_status:
            LOGGER.warning(f'Skipping instance {instance.id}'
                           f'(already in state state: {instance.state["Name"]})')
            continue
        
        if 'ebs' not in instance.root_device_type:
            LOGGER.warning(f'Skipping instance {instance.id} because root'
                           f' device is non-EBS one')
            continue

        LOGGER.info(f'{instance.id} is OK for traitment')
        elligible_instances_ids.append(instance.id)

    if not elligible_instances_ids:
        raise NoTargetFoundError(f'No elligible instances found. Nothing to do.')

    return elligible_instances_ids


def build_instance_filters() -> List[Dict]:
    """
    This function will return a list of dictionaries used to filter
    instances based on lambda's environment variables
    
    :returns: list of "AWS filters" dictionaries {'Name':'tag:<key>' Values: [<value>]}
    :raises NoTargetFoundError: if no tag will be found in environment variables
    """

    LOGGER.info('Seeking for Target environment variables')
    filters = []
    for key in os.environ:
        if key.startswith('Target'):
            LOGGER.info(f'Found {key} with value {os.environ[key]}')
            tag_name, tag_value = os.environ[key].split(':')
            filters.append({'Name': f'tag:{tag_name}', 'Values': [tag_value]})

    if not filters:
        raise NoTargetFoundError('No Target found in lambda environment variables')

    return filters


def start_instances_and_resume_asg(instance_ids: list) -> None:
    """
    Start the instances, wait the running state and then resume the ASGs if
    needed
    :param instance_ids: (list) A list of instance IDs
    """
    client = boto3.client('autoscaling')
    wait_for_running = boto3.client('ec2').get_waiter('instance_running')
    auto_scaling_groups = set()
    
    # First, we start the instances
    LOGGER.info(f'Start instances: {instance_ids}')
    boto3.client('ec2').start_instances(InstanceIds=instance_ids)
    
    # Then, we waiting for all the instances are in running state
    LOGGER.info('Waiting for instances reach running state')
    wait_for_running.wait(InstanceIds=instance_ids)
    
    # We're looking for existing ASGs
    LOGGER.info('Looking for existing auto scaling groups')
    asg = client.describe_auto_scaling_instances(InstanceIds=instance_ids)
    for instance in asg['AutoScalingInstances']:
        if instance['AutoScalingGroupName']:
            LOGGER.info(f"Found ASG {instance['AutoScalingGroupName']}")
            auto_scaling_groups.add(instance['AutoScalingGroupName'])

    # Finally, if ASGs was found, we resume them 
    for asg in list(auto_scaling_groups):
        LOGGER.info(f'Resuming ASG {asg}')
        client.resume_processes(AutoScalingGroupName=asg)


def suspend_asg_and_stop_instances(instance_ids: list) -> None:
    """
    Suspend ASG (if exists) and then stop EC2 instances
    :param instance_ids: (list) A list of instance IDs
    """
    client = boto3.client('autoscaling')
    auto_scaling_groups = set()
    
    # First, we are looking for all the related ASGs to the instance IDs
    LOGGER.info('Looking for existing auto scaling groups')
    asg = client.describe_auto_scaling_instances(InstanceIds=instance_ids)
    for instance in asg['AutoScalingInstances']:
        if instance['AutoScalingGroupName']:
            LOGGER.info(f"Found ASG {instance['AutoScalingGroupName']}")
            auto_scaling_groups.add(instance['AutoScalingGroupName'])

    # If ASGs was found, we suspend them to avoid instance termination
    for asg in list(auto_scaling_groups):
        LOGGER.info(f'Suspending ASG {asg}')
        client.suspend_processes(AutoScalingGroupName=asg)

    # Finally, we can stop the instances
    LOGGER.info(f'Stop instances: {instance_ids}')
    boto3.client('ec2').stop_instances(InstanceIds=instance_ids)


def main(desired_status: str, action_method) -> Dict:
    """
    Main function
    :param desired_status: The status we are looking for 
    :param action_method: The AWS Client method used to manipulate EC2 instances
    """
    try:
        ec2 = boto3.resource('ec2', region_name=os.environ['AWS_REGION'])

        # First, extract targets Tags from environment variables
        filters = build_instance_filters()

        # Second, search for instances using that tags
        LOGGER.info('Let\'s see if any instance match with that tags')
        instances = ec2.instances.filter(Filters=filters)
        if not len(list(instances)):
            raise NoTargetFoundError('No instances match with these tags. Exiting.')
        for instance in instances:
            LOGGER.info(f'Found instance {instance.id}')

        # Then, do some security checks (instance status and type of storage)
        target_instances = get_elligible_instances(instances, desired_status)

        # Finally let's do the job !
        LOGGER.info(f'Launch action on instances: {target_instances}')
        action_method(instance_ids=target_instances)
        
        return {'message': 'Traitment done !'}

    except NoTargetFoundError as error:
        LOGGER.error(f'Stop Lambda because: {error}')
        return json.dumps({'message': f'{error}', 'code': 500})


# Lambda Handlers (you can choose one to alter the behavior of this lambda)

def start_handler(event: dict, context: dict) -> Dict:
    """
    Start Handler use to only start instances
    """
    LOGGER.info('Beginning function : you want to START instances...')
    method = start_instances_and_resume_asg
    return main(desired_status='running', action_method=method)


def stop_handler(event: dict, context: dict) -> Dict:
    """
    Stop Handler use to only stop instances
    """
    LOGGER.info('Beginning function : you want to STOP instances...')
    method = suspend_asg_and_stop_instances
    return main(desired_status='stopped', action_method=method)


def start_or_stop_handler(event: dict, context: dict):
    """
    Generic Handler - Detect in event what action you want to do
    """
    raise NotImplementedError
