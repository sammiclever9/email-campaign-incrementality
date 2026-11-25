# Dataset provenance

## Original source

Kevin Hillstrom published the MineThatData E-Mail Analytics
and Data Mining Challenge on March 20, 2008.

Original experiment description:
https://blog.minethatdata.com/2008/03/

The dataset contains 64,000 customers who purchased within
the preceding twelve months. Customers were randomly assigned
to a men's merchandise email, a women's merchandise email,
or no email. Outcomes cover the following two weeks.

## Download used

This project used the compressed CSV mirror referenced by
the scikit-uplift dataset loader:

https://hillstorm1.s3.us-east-2.amazonaws.com/hillstorm_no_indices.csv.gz

Mirror documentation:
https://www.uplift-modeling.com/en/latest/_modules/sklift/datasets/datasets.html

The local analysis input is saved as data/raw/hillstrom.csv.
The raw dataset is downloaded separately.

## Variables and analysis roles

- segment records the assigned campaign or no-email control.
- conversion records whether a customer purchased.
- spend records spending during follow-up.
- visit records whether a customer visited the website.
- mens and womens describe prior merchandise purchases.

Primary outcome: purchase conversion.

Secondary outcome: spend per assigned customer, including
customers who spent zero.

These outcome roles describe this portfolio analysis and
are not claimed to be a preregistered plan.

## Scope

Results describe this historical experiment and its two-week
follow-up. Spending measures revenue; campaign costs and
product margins are unavailable.
