import pandas as pd

def most_frequent(List):
    return max(set(List), key = List.count)


def read_dataset(file):
    return pd.read_csv(file, sep='\t')