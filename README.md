# GMU CSI 796 Deep Learning - Spring 2019
> - ## Jupyter notebooks for the book "Deep Learning with Python"
>> - ### Adapted from material provided by Manning Publications

This repository contains Jupyter notebooks implementing the code samples found in the book [Deep Learning with Python (Manning Publications)](https://www.manning.com/books/deep-learning-with-python?a_aid=keras&a_bid=76564dff). The information contained within the notebooks have been modified to more concisely present the learning points using bullet lists.  Where code is modified from the original or added, these will all be commented with attribution and date.

These notebooks use Python 3.6 and Keras 2.0.8. They were generated on a p2.xlarge EC2 instance.

Within the notebooks, I will provide comments to identify which is the best value to time instance to use in the top comments.  Prices below do not account for storage costs for ebs attached storage of 75GB which adds about another penny an hour.  Most will use the p2.xlarge at $0.99/hr., however they charge by the second, so if you use it for 6 minutes it will be around 10 cents.

| Instance Type | vCPU | Memory GiB |      Price      |
|---------------|------|------------|:---------------:|
| p3.2xlarge    | 8    | 61 GiB     | $3.06 per Hour  |
| p3.8xlarge    | 32   | 244 GiB    | $12.24 per Hour |
| p3.16xlarge   | 64   | 488 GiB    | $24.48 per Hour |
| p2.xlarge     | 4    | 61 GiB     | $0.90 per Hour  |
| p2.8xlarge    | 32   | 488 GiB    | $7.20 per Hour  |
| p2.16xlarge   | 64   | 768 GiB    | $14.40 per Hour |
| g3.4xlarge    | 16   | 122 GiB    | $1.14 per Hour  |
| g3.8xlarge    | 32   | 244 GiB    | $2.28 per Hour  |
| g3.16xlarge   | 64   | 488 GiB    | $4.56 per Hour  |
| g3s.xlarge    | 4    | 30.5 GiB   | $0.75 per Hour  |

# Automated Cloud Formation Scripts

The instances should be created using the automated Cloud Formation script provided in the deploy folder.  This can be uploaded directly into the AWS CloudFormation Management Console or run on a local terminal using the AWS Command Line Interface (CLI). 
