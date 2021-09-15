import glob
import os

def assemble_run(project_folder):
    for x in glob.glob(project_folder + '/lxb/*'):
        if os.path.basename(x).split('_')[0] + '_CS5_' + os.path.basename(x).split('_')[2] not in [os.path.basename(y) for y in glob.glob(project_folder + 'assemble/*')]:
            pert = os.path.basename(x)
            name = pert.split('_')[0] + '_CS5_' + pert.split('_')[2]
            print name
            trunc = pert[0:7]
            os.system(
                'python assemble.py -config_filepath prism_pipeline.cfg -ptp /Volumes/cmap_obelix/pod/custom/PREP/PREP014-48_plate_key.txt -csdf /Volumes/cmap/data/vdb/PRISM/cell_set_definitions/PRISM_CS5_cellset.txt -dmf /Users/elemire/Workspace/projects/PRvDP/PR500_mapping.txt -out /Volumes/cmap_obelix/pod/custom/PREP/assemble/ -prn {} -dp_csv PR500 /Volumes/cmap_obelix/pod/custom/PREP/lxb/{}/{}.csv -pmp /Volumes/cmap_obelix/pod/custom/PREP/map_src/PREP014-48/{}.src'.format(
                    name, pert, pert, trunc))


def prep_run():
    for x in glob.glob('/Volumes/cmap_obelix/pod/custom/PREP/lxb/*PR500*'):
        if os.path.basename(x).split('_')[0] + '_CS5_' + os.path.basename(x).split('_')[2] not in [os.path.basename(y) for y in glob.glob('/Volumes/cmap_obelix/pod/custom/PREP/assemble/*')]:
            pert = os.path.basename(x)
            name = pert.split('_')[0] + '_CS5_' + pert.split('_')[2]
            print name
            trunc = pert[0:7]
            os.system('python ~/Workspace/merino/assemble.py -config_filepath prism_pipeline.cfg -ptp /Volumes/cmap_obelix/pod/custom/PREP/PREP014-48_plate_key.txt -csdf /Volumes/cmap/data/vdb/PRISM/cell_set_definitions/PRISM_PR500.CS5_definition.txt -dmf /Volumes/cmap/data/vdb/PRISM/analyte_mapping/PR500_mapping.txt -out /Volumes/cmap_obelix/pod/custom/PREP/assemble/ -prn {} -dp_csv PR500 /Volumes/cmap_obelix/pod/custom/PREP/lxb/{}/{}.jcsv -pmp /Volumes/cmap_obelix/pod/custom/PREP/map_src/PREP014-48/{}.src'.format(name, pert, pert, trunc))


def pasg_run():
    for x in glob.glob('/Volumes/cmap_obelix/pod/custom/PASG/lxb/*PR500*'):
        if os.path.basename(x).split('_')[0] + '_CS5_' + os.path.basename(x).split('_')[2] not in [os.path.basename(y) for y in glob.glob('/Volumes/cmap_obelix/pod/custom/PASG/assemble/*')]:
            pert = os.path.basename(x)
            name = pert.split('_')[0] + '_CS5_' + pert.split('_')[2]
            print name
            trunc = pert[0:7]
            os.system('python ~/Workspace/merino/assemble.py -config_filepath prism_pipeline.cfg -ptp /Volumes/cmap_obelix/pod/custom/PREP/PREP014-48_plate_key.txt -csdf /Volumes/cmap/data/vdb/PRISM/cell_set_definitions/PRISM_PR500.CS5_definition.txt -dmf /Users/elemire/Workspace/projects/PRvDP/PR500_mapping.txt -out /Volumes/cmap_obelix/pod/custom/PASG/assemble/ -prn {} -dp_csv PR500 /Volumes/cmap_obelix/pod/custom/PASG/lxb/{}/{}.csv -pmp /Users/elemire/Workspace/deal_with_this_later/PASG003.src'.format(name, pert, pert))


def pcal_run():
    for x in glob.glob('/Volumes/cmap_obelix/pod/custom/PCAL/lxb/*PR500_*'):
        if os.path.basename(x).split('_')[0] + '_CS5_' + os.path.basename(x).split('_')[2] not in [os.path.basename(y) for y in glob.glob('/Volumes/cmap_obelix/pod/custom/PCAL/assemble/*')]:
            pert = os.path.basename(x)
            name = pert.split('_')[0] + '_CS5_' + pert.split('_')[2]
            print name
            trunc = pert[0:7]
            os.system('python ~/Workspace/merino/assemble/assemble.py -config_filepath prism_pipeline.cfg -at PR500 -out /Volumes/cmap_obelix/pod/custom/PCAL/assemble/ -prn {} -csv /Volumes/cmap_obelix/pod/custom/PCAL/lxb/{}/{}.csv -pmp /Volumes/cmap_obelix/pod/custom/PCAL/map_src/PCAL075-102/{}.src'.format(name, pert, pert, trunc))

def pcal_t2b_run():
    for x in glob.glob('/Volumes/cmap_obelix/pod/custom/PCAL/lxb/*PR500.2*'):
        if os.path.basename(x).split('_')[0] + '_CS5_' + os.path.basename(x).split('_')[2] not in [os.path.basename(y) for y in glob.glob('/Volumes/cmap_obelix/pod/custom/PCAL/assemble/*')]:
            pert = os.path.basename(x)
            name = pert.split('_')[0] + '_CS5_' + pert.split('_')[2]
            print name
            trunc = pert[0:7]
            os.system('python ~/Workspace/merino/assemble.py -config_filepath prism_pipeline.cfg -out /Volumes/cmap_obelix/pod/custom/PCAL/assemble/ -prn {} -csv /Volumes/cmap_obelix/pod/custom/PCAL/lxb/{}/{}.jcsv -pmp /Volumes/cmap_obelix/pod/custom/PCAL/map_src/PCAL103-126/plate_maps/{}.src -at PR500'.format(name, pert, pert, trunc))


def pmts_run():
    for x in glob.glob('/Volumes/cmap_obelix/pod/custom/PMTS/lxb/combined/*PR500*'):
        if os.path.basename(x).split('_')[0] + '_CS5_' + os.path.basename(x).split('_')[2] not in [os.path.basename(y) for y in glob.glob('/Volumes/cmap_obelix/pod/custom/PMTS/assemble/*')]:
            pert = os.path.basename(x)
            name = pert.split('_')[0] + '_CS5_' + pert.split('_')[2]
            print name
            trunc = pert[0:7]
            os.system('python ~/Workspace/merino/assemble.py -config_filepath prism_pipeline.cfg -ptp /Volumes/cmap_obelix/pod/custom/PCAL/map_src/PCAL103-126/plate_tracking/PCAL103-126_plate_tracking.txt -csdf /Volumes/cmap/data/vdb/PRISM/cell_set_definitions/PRISM_CS5_cellset.txt -dmf /Volumes/cmap/data/vdb/PRISM/analyte_mapping/PR500_mapping.txt -out /Volumes/cmap_obelix/pod/custom/PMTS/assemble/ -prn {} -dp_csv PR500 /Volumes/cmap_obelix/pod/custom/PMTS/lxb/combined/{}/{}.csv -pmp /Volumes/cmap_obelix/pod/custom/PMTS/map_src/PMTS008-11/{}.src'.format(name, pert, pert, trunc))

def pmcl_run():
    for x in glob.glob('/Volumes/cmap_obelix/pod/custom/PMCL/lxb/combined/*PR500*'):
        if os.path.basename(x).split('_')[0] + '_CS5_' + os.path.basename(x).split('_')[2] not in [os.path.basename(y) for y in glob.glob('/Volumes/cmap_obelix/pod/custom/PMCL/assemble/*')]:
            pert = os.path.basename(x)
            name = pert.split('_')[0] + '_CS5_' + pert.split('_')[2]
            print name
            trunc = pert[0:7]
            os.system('python ~/Workspace/merino/assemble.py -config_filepath prism_pipeline.cfg -ptp /Volumes/cmap_obelix/pod/custom/PCAL/map_src/PCAL103-126/plate_tracking/PCAL103-126_plate_tracking.txt -csdf /Volumes/cmap/data/vdb/PRISM/cell_set_definitions/PRISM_CS5_cellset.txt -dmf /Volumes/cmap/data/vdb/PRISM/analyte_mapping/PR500_mapping.txt -out /Volumes/cmap_obelix/pod/custom/PMCL/assemble/ -prn {} -dp_csv PR500 /Volumes/cmap_obelix/pod/custom/PMCL/lxb/combined/{}/{}.csv -pmp /Volumes/cmap_obelix/pod/custom/PMCL/map_src/{}.src'.format(name, pert, pert, trunc))


def pcal_t3a():
    for x in glob.glob('/Volumes/cmap_obelix/pod/custom/PCAL/lxb/*PR500.3*'):
        if os.path.basename(x).split('_')[0] + '_CS5_' + os.path.basename(x).split('_')[2] not in [os.path.basename(y) for y in glob.glob('/Volumes/cmap_obelix/pod/custom/PCAL/assemble/*')]:
            pert = os.path.basename(x)
            map = pert.replace('.L2', '')
            map = map.replace('.L3', '')
            name = pert.split('_')[0] + '_CS5_' + pert.split('_')[2]
            print name
            trunc = pert[0:7]
            os.system('python ~/Workspace/merino/assemble.py -config_filepath prism_pipeline.cfg -ptp /Volumes/cmap_obelix/pod/custom/PREP/PREP014-48_plate_key.txt -csdf /Volumes/cmap/data/vdb/PRISM/cell_set_definitions/PRISM_PR500.CS5_definition.txt -dmf /Volumes/cmap/data/vdb/PRISM/analyte_mapping/PR500_mapping.txt -out /Volumes/cmap_obelix/pod/custom/PCAL/assemble/ -prn {} -dp_csv PR500 /Volumes/cmap_obelix/pod/custom/PCAL/lxb/{}/{}.csv -pmp /Volumes/cmap_obelix/pod/custom/PCAL/elwork/PCAL_T3A/map_src/PCAL127-155/maps/{}.src'.format(name, pert, pert, map))

def cbrant():
    for x in glob.glob('/Volumes/cmap_obelix/pod/custom/CBRANT/lxb/*'):
        if os.path.basename(x).replace('KJ100_', 'KJ100.').replace('_CP2.1', '') not in [os.path.basename(y) for y in glob.glob('/Volumes/cmap_obelix/pod/custom/CBRANT/assemble/*')]:
            pert = os.path.basename(x)
            name = pert.replace('KJ100_', 'KJ100.')
            name = name.replace('_CP2.1', '')
            print name
            trunc = pert[0:9]
            os.system('python ~/Workspace/merino/assemble.py -config_filepath prism_pipeline.cfg -ptp /Volumes/cmap_obelix/pod/custom/PREP/PREP014-48_plate_key.txt -csdf /Volumes/cmap/data/vdb/PRISM/cell_set_definitions/PRISM_PR500.CS5_definition.txt -dmf /Volumes/cmap/data/vdb/PRISM/analyte_mapping/copin_p904.p906.P907.P915_mapping.txt -out /Volumes/cmap_obelix/pod/custom/CBRANT/assemble/ -prn {} -dp_csv PR500 /Volumes/cmap_obelix/pod/custom/CBRANT/lxb/{}/{}.csv -pmp /Volumes/cmap_obelix/pod/custom/CBRANT/map_src/{}.src'.format(name, pert, pert, trunc))


def pbrant():
    for x in glob.glob('/Volumes/cmap_obelix/pod/custom/PBRANT/lxb/*'):
        if os.path.basename(x).replace('KJ100_', 'KJ100.').replace('_PR500.3', '') not in [os.path.basename(y) for y in glob.glob('/Volumes/cmap_obelix/pod/custom/PBRANT/assemble/*')]:
            pert = os.path.basename(x)
            name = pert.replace('KJ100_', 'KJ100.')

            if '_PR500.3_' in name:
                name = name.replace('_PR500.3_', '_CS5_')

            name = name.replace('_PR500.3', '')
            print name
            trunc = pert[0:9]
            os.system('python ~/Workspace/merino/assemble.py -config_filepath prism_pipeline.cfg -ptp /Volumes/cmap_obelix/pod/custom/PREP/PREP014-48_plate_key.txt -csdf /Volumes/cmap/data/vdb/PRISM/cell_set_definitions/PRISM_PR500.CS5_definition.txt -dmf /Volumes/cmap/data/vdb/PRISM/analyte_mapping/PR500_mapping.txt -out /Volumes/cmap_obelix/pod/custom/PBRANT/assemble/ -prn {} -dp_csv PR500 /Volumes/cmap_obelix/pod/custom/PBRANT/lxb/{}/{}.csv -pmp /Volumes/cmap_obelix/pod/custom/PBRANT/map_src/{}.src'.format(name, pert, pert, trunc))



