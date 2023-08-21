import pandas as pd
import argparse
import requests
import os
import boto3
import gzip
import io


def make_request_url_filter(endpoint_url, where=None, fields=None):
    clauses = []
    if where:
        where_clause = '"where":{'
        wheres = []
        for k, v in where.items():
            wheres.append('"{k}":"{v}"'.format(k=k, v=v))
        where_clause += ','.join(wheres) + '}'
        clauses.append(where_clause)

    if fields:
        fields_clause = '"fields":{'
        fields_list = []
        if type(fields) == dict:
            for k, v in fields.items():
                fields_list.append('"{k}":"{v}"'.format(k=k, v=v))
        elif type(fields) == list:
            for field in fields:
                fields_list.append('"{k}":"{v}"'.format(k=field, v="true"))
        fields_clause += ','.join(fields_list) + '}'
        clauses.append(fields_clause)

    if len(clauses) > 0:
        # print(endpoint_url.rstrip("/") + '?filter={' +  ','.join(clauses) + '}')
        return endpoint_url.rstrip("/") + '?filter={' + requests.utils.quote(','.join(clauses)) + '}'
    else:
        return endpoint_url


def get_data_from_db(endpoint_url, user_key, where=None, fields=None):
    request_url = make_request_url_filter(endpoint_url, where=where, fields=fields)
    response = requests.get(request_url, headers={'user_key': user_key, 'prism_key': 'prism_mts'})
    print(request_url)
    if response.ok:
        return response.json()
    else:
        response.raise_for_status()


def load_df_from_s3(partial_filename, prefix, bucket_name='macchiato.clue.io'):
    s3 = boto3.client('s3')

    # List objects in the bucket with the given prefix
    objects = s3.list_objects_v2(Bucket=bucket_name, Prefix=prefix)

    # Find the file that contains the partial filename
    matching_file = None
    for obj in objects.get('Contents', []):
        if partial_filename in obj['Key']:
            matching_file = obj['Key']
            break

    if not matching_file:
        raise ValueError(f"No file found with partial name: {partial_filename}")

    # Get the object from S3
    response = s3.get_object(Bucket=bucket_name, Key=matching_file)
    gzipped_bytes = response['Body'].read()

    # Decompress the gzipped bytes
    with gzip.GzipFile(fileobj=io.BytesIO(gzipped_bytes)) as gz:
        df = pd.read_csv(gz)

    return df


def process_data(build, screen):
    # load data
    level3_data = load_df_from_s3(partial_filename='LEVEL3',
                                  prefix=f"builds/{build}/build/")

    sw_data = pd.DataFrame(get_data_from_db(endpoint_url=SW_URL,
                                            user_key=API_KEY,
                                            where={"screen": screen}))

    sw_data.rename(columns={'assay_well_position': 'pert_well'}, inplace=True)

    # columns to match on
    cols_to_match = ['screen', 'pert_plate', 'pert_well', 'pool_id', 'replicate']

    # Merge the two dataframes on the specified columns with the indicator argument
    merged = level3_data.merge(sw_data[cols_to_match],
                               on=cols_to_match,
                               how='left',
                               indicator=True)

    # Filter out the rows that are present in both dataframes
    level3_data_filtered = merged[merged['_merge'] == 'left_only'].drop(columns=['_merge'])

    # Filter the rows that are present in both dataframes to get the values that are filtered out
    filtered_out_values = merged[merged['_merge'] == 'both'].drop(columns=['_merge'])

    return level3_data_filtered, filtered_out_values


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Take a build name and screen_id and filter out skipped Echo wells."
                                                 "Return a pruned level3 df for use in the MTS pipeline.")
    parser.add_argument("-b", "--build", help="Name of the build on S3.")
    parser.add_argument("-s", "--screen", help="Name of the screen.")

    args = parser.parse_args()
    API_KEY = os.environ['API_KEY']
    API_URL = 'https://dev-api.clue.io/api/'
    SW_URL = API_URL + 'v_assay_plate_skipped_well/'
    BUCKET_NAME = 'macchiato.clue.io'

    process_data(build=args.build, screen=args.screen)
