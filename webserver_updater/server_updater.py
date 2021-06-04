import os.path as path
import pandas as pd
import time
import glob
import matplotlib.pyplot as plt

##############
# FILE PATHS #
##############

dir_webserver = "/data/webserver"
dir_pipeline = "/data/pipeline"

file_log = dir_pipeline + '/pipeline_log.txt'
file_pangolin = dir_pipeline + '/lineage_report.csv'
file_server_data = dir_pipeline + '/webserver_data.xlsx'
file_figure_suffix = 'barcode_coverge.png'
file_home_page = dir_webserver + "/index.html"


####################
# Custom Functions #
####################

def generateHTMLLink(url, text):
    return f'<a href="{url}">{text}</a>'

def generateHTMLTableRow(header=False, *args):
    row_string = "<tr>"
    for arg in args:
        if header:
            row_string += f"<th>{arg}</th>"
        else:
            row_string += f"<td>{arg}</td>"
    row_string += "</tr>\n"
    return row_string

def generateHTMLTable(html_table_rows):
    table_string = "<font size=4>\n"
    table_string += '<table border=1 style="width:65%">\n'
    table_string += html_table_rows
    table_string += "</table>\n"
    table_string += "</font>"
    return table_string

def printToLog(message):
    time_stamp = time.strftime( "%Y/%m/%d %H:%M:%S",time.localtime(time.time()))
    with open(file_log, "a") as f:
        f.write(f"{time_stamp}  -  " + message + '\n')


def processBarcodeDepths(barcode, time_stamp):
    path_barcode = dir_pipeline + '/' + barcode
    barcode_list = glob.glob(path_barcode + "*.depths")
    if len(barcode_list) == 2:
        bar1 = pd.read_csv(barcode_list[0], delim_whitespace=True, header=None)
        bar2 = pd.read_csv(barcode_list[1], delim_whitespace=True, header=None)
        barcode_depth = bar1[3] + bar2[3]

        new_df_row = {}
        new_df_row['coverage_average'] = barcode_depth.mean()
        new_df_row['coverage_percent'] = sum(barcode_depth > 0) / len(barcode_depth)
        new_df_row['coverage_lowest5'] = barcode_depth.groupby(pd.qcut(barcode_depth,20)).mean()[0]

    return new_df_row, barcode_depth            

def appendNewCoverageSubplot(barcode_depths, barcode_stats, barcode_name):
        barcode_depths.plot.area(xlim=[0,len(barcode_depths)])
        barcode_depths.plot(color='k')
        plt.title(f'{barcode_name} Coverage', fontsize=16)
        plt.axline((0, barcode_stats['coverage_average']), (1, barcode_stats['coverage_average']), linewidth=4, color='r')
        plt.axline( (0,barcode_stats['coverage_lowest5']), (1,barcode_stats['coverage_lowest5']),color='r',linewidth=2, linestyle='--')
        plt.yscale('log')
        plt.ylim([.8,barcode_depths.max()])

def appendNewTimeSeriesSubplot(barcode_df, time_start, barcode_name):
    plot_df = pd.DataFrame()
    plot_df['time'] = (barcode_df['modified'] - time_start) / 60
    plot_df['coverage'] = barcode_df['percent_coverage']
    plot_df.plot(x='time')
    plt.title(f'{barcode_name} Percent Coverage', fontsize=16)
    plt.xlabel('Time (minutes)', fontsize=13)
    plt.ylabel('Percent Coverage', fontsize=13)
    plt.ylim([0, 100])
    
################
# MAIN PROGRAM #
################

printToLog("# # # # #")
printToLog("Run page updater starting")
# Continue if lineage csv file exists
if path.exists(file_pangolin):
    printToLog(f"{file_pangolin} was found")
    csv_lineage = pd.read_csv(file_pangolin)
    csv_lineage.fillna('', inplace=True)

    # Change failed values to be less confusing
    csv_lineage.loc[csv_lineage["lineage"]=='None',"conflict"] = 'NA'

    first_pass = False
    barcodes_old = []
    current_time = round(path.getmtime(file_pangolin))

    if path.exists(file_server_data):
        printToLog(f"{file_server_data} was found")
        base_df = pd.read_excel(file_server_data, sheet_name='base')
        start_time_epoch = base_df.loc[0,'StartTime']
        barcodes_old = base_df['barcodes']

    else:
        printToLog(f"{file_server_data} was not found")
        base_df = pd.DataFrame()
        start_time_epoch = current_time
        first_pass = True

    start_time = time.strftime('%Y-%m-%d_%H%m', time.localtime(start_time_epoch))

    i=0
    html_tab_r = generateHTMLTableRow(True,
                                      "Sample ID", 
                                      "Lineage", 
                                      "Conflict", 
                                      "Note",
                                      "Percent Coverage",
                                      "Average Coverage",
                                      "Coverage, Lowest 5%")

    barcodes_present = [ (idx,split) for idx, barcode in enumerate(csv_lineage['taxon']) for split in barcode.split('/') if "barcode" in split]
    fig = plt.figure(figsize=[10,5*len(barcodes_present)])

    # Extract data per barcode, save XLSX sheet, generate subplot
    for idx, barcode in barcodes_present:
        barcode_df, depth = processBarcodeDepths(barcode)
        barcode_df['lineage'] = csv_lineage.loc[idx, 'lineage']
        barcode_df['note'] = csv_lineage.loc[idx, 'note']
        barcode_df['conflict'] = csv_lineage.loc[idx, 'conflict']
        barcode_df['modified'] = current_time    
        printToLog(f"New data processed: {barcode_df}")

        barcode_df_xlsx = pd.DataFrame()

        if barcode in barcodes_old:
            printToLog(f"{barcode} was found in {file_server_data}")
            barcode_df_xlsx = pd.read_excel(file_server_data, sheet_name=barcode)

        barcode_df_xlsx.append(barcode_df, ignore_index=True)

        printToLog(f"Creating xlsx page '{barcode}' in {file_server_data}")
        writer = pd.ExcelWriter(file_server_data, engine=xlsxwriter)
        barcode_df_xlsx.to_excel(writer, sheet_name=barcode,index=False)
        writer.save()

        # Generate HTML row
        html_tab_r += generateHTMLTableRow( False, barcode, 
                                            barcode_df['lineage'],
                                            barcode_df['conflict'],
                                            barcode_df['note'],
                                            barcode_df['coverage_percent'],
                                            barcode_df['coverage_average'],
                                            barcode_df['coverage_lowest5'])


        # Generate subplots
        i = i + 1
        plt.subplots(len(barcodes_present), 2, i)
        appendNewCoverageSubplot(depth, barcode_df, barcode)

        plt.subplots(len(barcodes_present), 2, i+1)
        appendNewTimeSeriesSubplot(barcode_df_xlsx, start_time_epoch, barcode)



    # Create the base page
    new_barcodes = [barcode for _, barcode in barcodes_present]
    base_df = pd.DataFrame()
    base_df['barcodes'] = new_barcodes
    base_df['StartTime'] = start_time_epoch

    printToLog(f"Creating xlsx page 'base' in {file_server_data}")
    writer = pd.ExcelWriter(file_server_data, engine=xlsxwriter)
    base_df.to_excel(writer, sheet_name='base',index=False)
    writer.save()
    
    # Generate new figure from session data
    printToLog("Saving figure")
    file_figure_name = dir_webserver + '/' + start_time + "_" + file_figure_suffix
    plt.savefig(file_figure_name, bbox_inches='tight', dpi=200)
    printToLog(f"{file_figure_name} was saved")

    # Generate HTML for run page
    printToLog("Generating run page HTML")
    html_image = f'<img src="{path.basename(file_figure_name)}" alt="figure" width="75%">'
    html_table = generateHTMLTable(html_tab_r)
    html_output = "<!DOCTYPE html>\n" \
                   "<html>\n" \
                   "<title> MinION Pangolin Pipeline </title>\n" \
                   "<body> \n"\
                   f"<h1>Run: {start_time}</h1> \n" \
                   f"Updates every 10 minutes. Last updated: {start_time}" \
                   f"{html_table} \n"\
                   f"{html_image} \n" \
                   "</body> \n" \
                   "</html>"
    file_run_page = dir_webserver + '/' + start_time + ".html"
    with open(file_run_page, 'wt') as f:
                f.write(html_output)

    printToLog(f"{file_run_page} was saved")
    # If first pass, insert link to run page on home page
    if first_pass:
        printToLog(f"Generating link to run page on {file_home_page}")
        html_link = generateHTMLLink(path.basename(file_run_page), f"Run: {start_time}")

        with open(file_home_page, 'r+t') as f:
            buffer = f.readlines()
            for index, line in enumerate(buffer):
                if '<h2>' in line:
                    buffer.insert(index + 1, html_link + '\n<br>\n')
                    break
            f.seek(0)
            f.writelines(buffer)

        printToLog("Link created on home page")
else:
    printToLog(f"{file_pangolin} not found")

printToLog("End of run page updater")