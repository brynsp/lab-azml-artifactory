"""
Sample Azure ML environment and deployment configuration

This script demonstrates how to create and deploy a custom environment
using a container image from ACR (synchronized from Artifactory).
"""

from azure.ai.ml import MLClient
from azure.ai.ml.entities import Environment, ManagedOnlineEndpoint, ManagedOnlineDeployment, CodeConfiguration
from azure.identity import DefaultAzureCredential
import yaml


def create_environment(ml_client: MLClient, acr_name: str, image_name: str = "contoso-lab/sample-ml-model", tag: str = "latest"):
    """Create a custom environment from ACR image."""
    
    env_name = "contoso-artifactory-env"
    
    # Create environment from ACR image
    environment = Environment(
        name=env_name,
        image=f"{acr_name}.azurecr.io/{image_name}:{tag}",
        description="Test environment created from Artifactory-sourced container"
    )
    
    # Create the environment
    env = ml_client.environments.create_or_update(environment)
    print(f"Environment created: {env.name}")
    return env


def create_endpoint(ml_client: MLClient, endpoint_name: str = "contoso-lab-endpoint"):
    """Create a managed online endpoint."""
    
    endpoint = ManagedOnlineEndpoint(
        name=endpoint_name,
        description="Endpoint for testing Artifactory-sourced containers",
        auth_mode="key"
    )
    
    # Create the endpoint
    endpoint = ml_client.online_endpoints.begin_create_or_update(endpoint).result()
    print(f"Endpoint created: {endpoint.name}")
    return endpoint


def create_deployment(ml_client: MLClient, endpoint_name: str, env_name: str, deployment_name: str = "default"):
    """Create a deployment using the custom environment."""
    
    deployment = ManagedOnlineDeployment(
        name=deployment_name,
        endpoint_name=endpoint_name,
        environment=f"azureml:{env_name}@latest",
        code_configuration=CodeConfiguration(
            code="./examples/azure-ml",
            scoring_script="score.py"
        ),
        instance_type="Standard_DS2_v2",
        instance_count=1
    )
    
    # Create the deployment
    deployment = ml_client.online_deployments.begin_create_or_update(deployment).result()
    print(f"Deployment created: {deployment.name}")
    return deployment


def test_endpoint(ml_client: MLClient, endpoint_name: str):
    """Test the deployed endpoint."""
    
    # Sample test data
    test_data = {
        "data": [
            {"feature1": 1.0, "feature2": 2.0},
            {"feature1": 3.0, "feature2": 4.0}
        ]
    }
    
    # Invoke the endpoint
    response = ml_client.online_endpoints.invoke(
        endpoint_name=endpoint_name,
        request_file=None,
        deployment_name="default"
    )
    
    print(f"Endpoint response: {response}")
    return response


def main():
    """Main deployment workflow."""
    
    # Configuration - update these values based on your deployment
    SUBSCRIPTION_ID = "<your-subscription-id>"
    RESOURCE_GROUP = "rg-lab-azml-artifactory"
    WORKSPACE_NAME = "lab-azml-artifactory-ml-workspace"
    ACR_NAME = "<your-acr-name>"  # From terraform output
    
    try:
        # Initialize ML client
        credential = DefaultAzureCredential()
        ml_client = MLClient(
            credential=credential,
            subscription_id=SUBSCRIPTION_ID,
            resource_group_name=RESOURCE_GROUP,
            workspace_name=WORKSPACE_NAME
        )
        
        print(f"Connected to ML workspace: {WORKSPACE_NAME}")
        
        # Step 1: Create environment from ACR image
        env = create_environment(ml_client, ACR_NAME)
        
        # Step 2: Create endpoint
        endpoint_name = "contoso-lab-endpoint"
        endpoint = create_endpoint(ml_client, endpoint_name)
        
        # Step 3: Create deployment
        deployment = create_deployment(ml_client, endpoint_name, env.name)
        
        # Step 4: Test the endpoint
        print("Testing endpoint...")
        response = test_endpoint(ml_client, endpoint_name)
        
        print("\n" + "="*50)
        print("✓ Deployment completed successfully!")
        print(f"Endpoint: {endpoint_name}")
        print(f"Environment: {env.name}")
        print(f"Image: {ACR_NAME}.azurecr.io/contoso-lab/sample-ml-model:latest")
        print("="*50)
        
    except Exception as e:
        print(f"Error during deployment: {str(e)}")
        raise


if __name__ == "__main__":
    print("Azure ML Deployment Script for Contoso Lab")
    print("Update the configuration variables before running.")
    print("Ensure you have the Azure ML SDK v2 installed:")
    print("pip install azure-ai-ml azure-identity")
    print()
    
    # Uncomment the line below to run the deployment
    # main()