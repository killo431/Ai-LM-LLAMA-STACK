"""Main orchestration entrypoint for the CrewAI multi-agent system."""
import yaml
from crewai import Crew
from agents import agent_definitions
from memory.qdrant_storage import QdrantStorage


def main():
    try:
        with open('config/crewai_project.yaml') as f:
            project_config = yaml.safe_load(f)


        # Initialize memory with Qdrant
        memory = QdrantStorage(uri=project_config['qdrant']['url'])


        # Initialize Crew with config and memory
        crew = Crew(config=project_config, memory=memory)


        # Register agents
        crew.register_agents(agent_definitions.get_agents())


        # Start orchestration
        crew.start()


    except Exception as e:
        print(f"Orchestrator failure: {e}")


if __name__ == "__main__":
    main()
