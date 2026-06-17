dss_version = '1.9'
sp_version = '6.1'

QSP_SCROLLS = {'1Qisaa', '1QisaaI', '1QisaaII', '2Q3', '4Q13', '4Q20', '2Q7', '4Q27', '1Q4', '2Q12',
               '4Q37', '4Q38', '4Q38a', '4Q40', '4Q53', '4Q57', '2Q13', '4Q78', '4Q80', '4Q82', '4Q128',
               '4Q129', '4Q134', '4Q135', '4Q136', '4Q137', '4Q138', '4Q139', '4Q140', '4Q141', '4Q142',
               '4Q143', '4Q144', '4Q158', '4Q364', '4Q365', '4Q96', '4Q111', '4Q109', '11Q5', '11Q6', '11Q7', '11Q8',
               }

# SP word nodes are stored in CSV files with this offset added to avoid collisions
# with MT node IDs in the shared Text-Fabric node space.
# Use normalize_sp_id() before TF lookups and denormalize_sp_id() when writing back.
SP_TF_OFFSET = 100_000


def normalize_sp_id(tf_id: int, manuscript: str) -> int:
    """Convert a CSV-stored tf_id to the actual Text-Fabric node ID."""
    return tf_id - SP_TF_OFFSET if manuscript == 'SP' else tf_id


def denormalize_sp_id(tf_node_id: int, manuscript: str) -> int:
    """Convert a Text-Fabric node ID back to the CSV-stored tf_id."""
    return tf_node_id + SP_TF_OFFSET if manuscript == 'SP' else tf_node_id