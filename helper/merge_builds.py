import sys
import os
import glob
import pandas as pd
from PyPDF2 import PdfFileMerger

if __name__ == "__main__":

    # directories to run concatenation on
    dir1 = sys.argv[1]
    dir2 = sys.argv[2]
    # output directory
    destination = sys.argv[3]

    # search for all csv files in first directory
    dir1_search = dir1 + "/**/**.csv"
    dir1_csvs = [i for i in glob.glob(dir1_search, recursive=True)]

    # for each find the matching file in second and combine
    for file in dir1_csvs:
        print(file[len(dir1):])
        dir1_file = pd.read_csv(file, low_memory=False)
        dir2_path = dir2 + file[len(dir1):]

        # if there is a matching one, read it
        if os.path.isfile(dir2_path):
            dir2_file = pd.read_csv(dir2_path, low_memory=False)
            combined_file = pd.concat([dir1_file, dir2_file])
        else:
            combined_file = dir1_file

        # write out (making directory if not there)
        out_path = destination + file[len(dir1):]
        if not os.path.isdir(os.path.dirname(out_path)):
            os.makedirs(os.path.dirname(out_path), )
        combined_file.to_csv(out_path, index=False, na_rep="NA")

    # repeat but with pdf files (dose-response figures)
    dir1_search = dir1 + "/**/**.pdf"
    dir1_pdfs = [i for i in glob.glob(dir1_search, recursive=True)]

    for file in dir1_pdfs:
        pdfs = [file]
        dir2_file = dir2 + file[len(dir1):]
        if os.path.isfile(dir2_file):
            pdfs.append(dir2_file)

        # use PyPDF2 to combine
        merger = PdfFileMerger()
        for pdf in pdfs:
            merger.append(pdf)
        out_path = destination + file[len(dir1):]
        merger.write(out_path)
        merger.close()
    print("Done. Merged {0} files into {1}".format(len(dir1_csvs) + len(dir1_pdfs), destination))
