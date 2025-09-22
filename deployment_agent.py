"""
Autonomous Deployment Agent for automated build, run, and debugging.
"""
import subprocess
import os
import time


class AutonomousDeploymentAgent:
    def __init__(self):
        self.base_dir = os.path.abspath(os.path.dirname(__file__))
        self.log_file = os.path.join(self.base_dir, "logs", "deployment_agent.log")
        os.makedirs(os.path.dirname(self.log_file), exist_ok=True)
        self.retry_attempts = 3


    def log(self, msg):
        print(msg)
        with open(self.log_file, "a") as f:
            f.write(msg + "\n")


    def run_command(self, cmd, max_retries=1, delay=5):
        for attempt in range(max_retries):
            self.log(f"Running command (attempt {attempt+1}): {cmd}")
            proc = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            self.log(proc.stdout)
            if proc.stderr:
                self.log(f"STDERR: {proc.stderr}")
            if proc.returncode == 0:
                return proc
            else:
                self.log(f"Command failed with code {proc.returncode}")
                if attempt < max_retries - 1:
                    self.log(f"Retrying in {delay} seconds...")
                    time.sleep(delay)
        raise RuntimeError(f"Command failed after {max_retries} attempts: {cmd}")


    def install_dependencies(self):
        self.log("Installing dependencies...")
        self.run_command("powershell ./scripts/install_deps.ps1")
        self.run_command("wsl ./scripts/setup_wsl.sh")


    def build_docker_images(self):
        self.log("Building Docker images...")
        self.run_command("docker-compose build", max_retries=2)


    def start_containers(self):
        self.log("Starting containers...")
        self.run_command("docker-compose up -d", max_retries=2)


    def verify_service(self, url, retries=5, wait=3):
        import requests
        self.log(f"Verifying service at {url}")
        for attempt in range(retries):
            try:
                response = requests.get(url, timeout=5)
                if response.ok:
                    self.log(f"Service at {url} responded successfully.")
                    return True
            except Exception as e:
                self.log(f"Attempt {attempt+1} failed: {e}")
            time.sleep(wait)
        self.log(f"Failed to verify service at {url} after {retries} attempts.")
        raise RuntimeError(f"Service verification failed: {url}")


    def run_orchestrator(self):
        self.log("Running CrewAI orchestrator")
        self.run_command("wsl python3 run_crewai.py", max_retries=3)


    def full_deploy_cycle(self):
        try:
            self.install_dependencies()
            self.build_docker_images()
            self.start_containers()
            self.verify_service("http://localhost:6333/health")
            self.verify_service("http://localhost:11434")
            self.run_orchestrator()
        except Exception as e:
            self.log(f"Deployment failed: {e}")


if __name__ == "__main__":
    agent = AutonomousDeploymentAgent()
    agent.full_deploy_cycle()
