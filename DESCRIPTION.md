# DevOps Midterm Project Description

## Technical Requirements

### Web Application (Technology Agnostic)

Build a small web application using any language or framework (Python).
Must include: At least one dynamic route, an input form/endpoint, and at least one automated unit test.

### Version Control (Git)

Maintain at least two active branches: main and dev.
Follow best practices with frequent, clean, and descriptive commit messages.

### Continuous Integration (CI)

Set up a pipeline using GitHub Actions or GitLab CI.
The pipeline must trigger automatically on every Push or Pull Request to run tests and code linting.

### Infrastructure as Code & Automation (IaC)

Tool Choice: Open (Ansible, Terraform, Pulumi, or advanced Bash/Python scripts).
Task: Environment preparation (installing runtimes, creating directories, configuration) must be fully automated and executable via a single command.

### Continuous Deployment (CD)

Set up an automated deployment to a local "Production" environment.
Demonstrate a Blue-Green Deployment simulation and provide a Rollback mechanism (script or manual step) to revert versions.

### Monitoring & Health Check

Create a script that periodically checks the application's status (health check) and logs the results to a file.

---

## Documentation & Submission (README.md)

The project must be submitted as a link to your repository. All documentation must be contained within the README.md file. You are required to describe every step in detail:

- **Step-by-Step Instructions:** A comprehensive guide on how to set up, run the automation, and deploy the project.
- **Embedded Screenshots:** Include images directly in the README as proof of:
  - Successful CI pipeline runs.
  - Successful IaC execution.
  - The deployment process and the running app.
  - Monitoring logs (Health Check results).
- **Tech Stack:** A list of all tools and languages used.
- **Workflow Diagram:** A visual representation of your CI/CD pipeline.
