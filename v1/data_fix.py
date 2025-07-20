import pandas as pd
import numpy as np

# Load the existing DimCustomer
dim_customer = pd.read_csv("DimCustomer.csv")  # adjust path if needed

# Make a copy to adjust
dim_customer_adj = dim_customer.copy()

np.random.seed(42)

# Gender skew: 65% Male, 30% Female, 5% Other
dim_customer_adj['gender'] = np.random.choice(
    ['Male', 'Female', 'Other'],
    size=len(dim_customer_adj),
    p=[0.65, 0.30, 0.05]
)

# Loyalty program skew: 70% True, 30% False
dim_customer_adj['loyalty_program'] = np.random.choice(
    [True, False],
    size=len(dim_customer_adj),
    p=[0.7, 0.3]
)

# Age skew: 15% in 18–25, 60% in 26–45, 25% in 46–70
def random_age():
    return np.random.choice(
        [np.random.randint(18, 25), np.random.randint(26, 45), np.random.randint(46, 70)],
        p=[0.15, 0.6, 0.25]
    )

dim_customer_adj['age'] = [random_age() for _ in range(len(dim_customer_adj))]

# Save adjusted dimension
dim_customer_adj.to_csv("DimCustomer_Adjusted.csv", index=False)

print("✅ Saved updated DimCustomer_Adjusted.csv")
