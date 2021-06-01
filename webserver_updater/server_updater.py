import os.path as path
import pandas as pd
import time
import matplotlib.pyplot as plt

##############
# FILE PATHS #
##############

dir_webserver = "/data/webserver"
dir_pipeline = "/data/pipeline"

file_log = dir_pipeline + '/pipeline_log.txt'
file_pangolin = dir_pipeline + '/lineage_report.csv'
file_server_data = dir_pipeline + '/webserver_data.csv'
file_figure_suffix = 'UncertaintyVsTime.png'
file_home_page = dir_webserver + "/index.html"


###################
# HTML FORMATTERS #
###################

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

def generateHTMLTable(csv_df):
    table_string = "<font size=4>\n"
    table_string += '<table border=1 style="width:65%">\n'
    table_string += generateHTMLTableRow(True,
                                         "Sample ID", 
                                         "Lineage", 
                                         "Conflict", 
                                         "Note")
    for index, row in csv_df.iterrows():
        table_string += generateHTMLTableRow(False,
                                             row["taxon"],
                                             row["lineage"],
                                             row["conflict"],
                                             row["note"])

    table_string += "</table>\n"
    table_string += "</font>"
    return table_string

def printToLog(message):
    time_stamp = time.strftime( "%Y/%m/%d %H:%M:%S",time.localtime(time.time()))
    with open(file_log, "a") as f:
        f.write(f"{time_stamp}  -  " + message + '\n')


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
    csv_lineage.loc[csv_lineage["lineage"]=='None',"conflict"] = 'None'

    # Open session data file if it exists
    if path.exists(file_server_data):
        printToLog(f"{file_server_data} was found")
        csv_data = pd.read_csv(file_server_data)
        add_link_to_home = False

    # If not, create a new dataframe and raise flag to make new link on home
    else:
        printToLog(f"{file_server_data} was not found. Creating new dataframe")
        csv_data=pd.DataFrame()
        add_link_to_home = True

    # Reformat new data to be figure friendly 
    new_row = {}
    for index, row in csv_lineage.iterrows():
        new_row[row['taxon']] = row['conflict']

    # Get the modified time stamp from the lineage csv
    new_row['modified'] = round(path.getmtime(file_pangolin))
    printToLog(f"New data processed: {new_row}")

    # Append data, clean missing values and save session dataframe
    csv_data = csv_data.append(new_row, ignore_index=True)
    csv_data = csv_data.apply(pd.to_numeric, errors='coerce', axis=1).fillna(100)
    csv_data.to_csv(file_server_data, index=False)
    printToLog(f"{file_server_data} was saved")

    # Get time stamp of first datapoint, t=0
    start_time = time.strftime('%Y-%m-%d_%H%m', time.localtime(csv_data['modified'][0]))

    # Reformat modified date to be minutes since first time stamp
    csv_data['modified'] = (csv_data['modified'] - csv_data['modified'][0]) / 60

    # Generate new figure from session data
    printToLog("Generating figure")
    file_figure_name = dir_webserver + '/' + start_time + "_" + file_figure_suffix
    plt.figure()
    csv_data.plot(x='modified').legend(loc='center left',bbox_to_anchor=(1.0, 0.5))
    plt.title('Lineage Uncertainty vs Time', fontsize=16)
    plt.xlabel('Time (minutes)', fontsize=13)
    plt.ylabel('Alternative Lineages', fontsize=13)
    plt.ylim([0.09, 100])
    plt.yscale('log')
    plt.savefig(file_figure_name, bbox_inches='tight', dpi=200)
    printToLog(f"{file_figure_name} was saved")

    # Generate HTML for run page
    printToLog("Generating run page HTML")
    html_table = generateHTMLTable(csv_lineage)
    html_image = f'<img src="{path.basename(file_figure_name)}" alt="figure" width="65%">'
    html_output = "<!DOCTYPE html>\n" \
                   "<html>\n" \
                   "<title> MinION Pangolin Pipeline </title>\n" \
                   "<body> \n"\
                   f"<h1>Run: {start_time}</h1> \n" \
                   f"{html_table} \n"\
                   f"{html_image} \n" \
                   "</body> \n" \
                   "</html>"
    file_run_page = dir_webserver + '/' + start_time + ".html"
    with open(file_run_page, 'wt') as f:
                f.write(html_output)

    printToLog(f"{file_run_page} was saved")
    # If first pass, insert link to run page on home page
    if add_link_to_home:
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