# Customer Churn Prediction

![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)
![Build](https://github.com/jbrdge/churn-prediction/actions/workflows/ci.yml/badge.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)


An end-to-end workflow for predicting customer churn. Data is ingested and cleaned in **MySQL**, modeled in **Python**, and prepared for visualization in **Tableau**.

---

## Project Overview

Customer churn is a critical business problem. Retaining customers is generally more cost-effective than acquiring new ones.  

This project shows how to:
- Load and clean data in a relational database
- Engineer features in SQL
- Train and evaluate a logistic regression model in Python

---

## Tools & Technologies

- **Python 3.12**: pandas, scikit-learn, mysql-connector, python-dotenv  
- **MySQL**: schema design, cleaning, feature engineering  
- **Tableau Public**: visualization of churn risk and revenue impact  
- **Jupyter Notebook**: documentation and modeling environment  
- **GitHub**: version control and reproducibility  

---

## Dataset
https://www.kaggle.com/datasets/blastchar/telco-customer-churn  

### Context
The dataset includes information about:  
- Customers who left within the last month (column: `Churn`)  
- Services each customer has signed up for (phone, internet, streaming, etc.)  
- Account information (tenure, contract, billing, charges)  
- Demographic information (gender, age, partners, dependents)  

---

## Project Structure
```
churn-prediction/
├── data/
│ └── Telco-Customer-Churn.csv
├── notebooks/
│ └── churn_regression.ipynb
├── scripts/
│ └── load_csv.sh
├── sql/
│ ├── archive/
│ │ └── telco_churn_database.sql
│ ├── 00_schema.sql
│ └── 01_post_load_transformations.sql
├── .env.example
├── .gitignore
├── environment.yml
├── requirements.txt
├── requirements-lock.txt
└── README.md
```

---

## Visualizations
A Tableau Public dashboard will be published here once available.  
Planned deliverables for `v0.6.0`:
- Interactive churn risk dashboard
- Customer segmentation breakdown
- Revenue impact analysis

---

## Setup

### 1. Clone the repository
```bash
git clone https://github.com/jbrdge/churn-prediction.git
cd churn-prediction
```

### 2. Configure environment variables
```bash
cp .env.example .env
# edit .env with your MySQL credentials
```

### 3. Install dependencies
#### Using pip
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

#### Using conda
```bash
conda env create -f environment.yml
conda activate churn-env
```

#### (Optional, for legacy notebook only)
```bash
python -m ipykernel install --user --name churn-wsl --display-name "Python (churn-wsl)"
```

---

## Database Setup (prerequisite)
Before running the notebook, prepare the database:

1. Create schema and customers table:
```bash
mysql -u churn -p < sql/00_schema.sql
```
2. Load the raw churn dataset into MySQL:
```bash
bash scripts/load_csv.sh
```

3. Run post-load transformations to build the clean table:
```bash
mysql -u churn -p churn_project < sql/01_post_load_transformations.sql
```

---

## Troubleshooting
```
ERROR 3948 (42000) at line 2: Loading local data is disabled; this must be enabled on both the client and server sides
```

To fix this error run:
```bash
sudo mysql -e "SHOW VARIABLES LIKE 'local_infile';"
```
If local_infile is OFF, enable it:
```bash
sudo mysql -e "SET GLOBAL local_infile = 1;"
```
Confirm:
```bash
sudo mysql -e "SHOW VARIABLES LIKE 'local_infile';"
```

---

## Roadmap

- ✅ [0.1.0] – Stabilized Baseline
   Pre-release baseline with cleanup, legacy notebook archived, and changelog introduced.

- ⏳ [0.2.0] – Repo Structure
   Planned: introduce clear Python/SQL repo layout and env templates.

- ⏳ [0.3.0] – Docker Compose
   Planned: add Dockerfile + docker-compose.yml with health checks and Makefile targets.

- ⏳ [0.4.0] – SQL ETL
   Planned: implement SQL schema + ETL loader.

- ⏳ [0.5.0] – Baseline Model
   Planned: provide baseline churn model CLI, save artifacts and metrics.

- ⏳ [0.6.0] – Tableau Dashboard  
  Planned: publish Tableau Public dashboard and link it from README.


---
## License
This project is licensed under the MIT License – see the [LICENSE](LICENSE) file for details.
