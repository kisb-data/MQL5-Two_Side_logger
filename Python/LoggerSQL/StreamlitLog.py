import streamlit as st
from Libs import SQLiteDataAccessExtLog
import pandas as pd
from datetime import datetime, timedelta, time
import os

# ------------------------------------------------------------------------------
# ------------------------------- Subroutines ----------------------------------
# ------------------------------------------------------------------------------

# Function to get start and end of the current week
def get_current_week():
    today = datetime.today()
    start = today - timedelta(days=today.weekday())
    end = start + timedelta(days=6)
    return start, end

# Function to get start and end of the previous week
def get_previous_week():
    today = datetime.today()
    start = today - timedelta(days=today.weekday() + 7)
    end = start + timedelta(days=6)
    return start, end

# import SQL database to pandas
def import_SQL_databes(path):

    # create class
    SQL = SQLiteDataAccessExtLog.DataAccess(path)

    # get tables
    tables = list()
    for item in SQL.GetTableNames():
        tables.append(item[0])
    
    # remove sqlite_sequence
    tables.remove('sqlite_sequence')

    # each column needs to be the same in all tables, add 'table' as table identifier in the database
    columns_pre = SQL.GetColumnNames([tables[0],])[0]
    columns_pre.insert(0, 'Table')

    logs = pd.DataFrame()

    for t in tables:
        data = SQL.SelectAllFromTable(t)
        data_with_table_name = [[t] + list(row) for row in data]
        df = pd.DataFrame(data_with_table_name, columns=columns_pre)
        logs = pd.concat([logs, df], ignore_index=True)

    # Convert 'Date' and 'Time' columns to appropriate types
    logs['Date'] = pd.to_datetime(logs['Date'])
    logs['Time'] = pd.to_datetime(logs['Time'], format='%H:%M:%S').dt.time

    # remove id
    logs.pop('id')

    return logs

# ------------------------------------------------------------------------------
# ------------------------ Data Access and Preprocessing -----------------------
# ------------------------------------------------------------------------------

# path to database
log_path = "C:\\"

# Set page configuration options
st.set_page_config(
    layout="wide",
    page_title="LogAnalysis",
    page_icon="🔢"
)

# create sidebar
with st.sidebar.title("Configuration"):
    
    # Text input for database path
    log_path = st.sidebar.text_input("Database Path", log_path)

    st.sidebar.markdown("""---""")

    # Color pickers with option "None"
    debug_color = st.sidebar.color_picker("Debug Color", "#4D964D")
    if st.sidebar.checkbox("No Debug Color"):
        debug_color = None
    
    position_color = st.sidebar.color_picker("Position Color", "#BDBD38")
    if st.sidebar.checkbox("No Position Color"):
        position_color = None

    warning_color = st.sidebar.color_picker("Warning Color", "#D05A5A")
    if st.sidebar.checkbox("No Warning Color"):
        warning_color = None

    st.sidebar.markdown("""---""")

    if st.sidebar.checkbox("Use limit message size."):
        message_limit = st.sidebar.number_input("Size:", min_value=5, value=25, step=1)
        use_limit_size=True
    else:
        use_limit_size=False

# check if database is exist
if os.path.exists(log_path):
    if os.path.isfile(log_path):
        # create pandas database
        logs = import_SQL_databes(log_path)

        # set default if session state not exist
        if 'Table' not in st.session_state:
            st.session_state.Table = list(set(logs['Table']))[0]

        # ------------------------------------------------------------------------------
        # ------------------------------ Log Analysis ----------------------------------
        # ------------------------------------------------------------------------------

        # create columns
        colA, colB, colC = st.columns([0.30,0.6,0.30])

        with colB:

            # description
            st.markdown('# 🔢 LogAnalysis')
            
            with st.container(border=True):

                # create columns
                col = st.columns([0.5,0.5])

                # select table
                with col[0]:

                    selected_table = st.selectbox("Select Table", set(logs['Table']), index=list(set(logs['Table'])).index(st.session_state.Table))
                    is_rerun = st.session_state.Table != selected_table
                    st.session_state.Table=selected_table
                    logs=logs[logs['Table']==selected_table]
                    if is_rerun:
                        st.rerun()

                # create columns
                cols = st.columns(4)

                # single select options
                with cols[0]:
                    account = st.selectbox("Select Account", list(set(logs['Account'])))
                    logs = logs[logs['Account'] == account]
                with cols[1]:
                    name = st.selectbox("Select Name", set(logs['Name']))
                    logs=logs[logs['Name'] == name]
                with cols[2]:
                    symbol = st.selectbox("Select Symbol", list(set(logs['Symbol'])))
                    logs = logs[logs['Symbol'] == symbol]
                with cols[3]:
                    period = st.selectbox("Select Period", list(set(logs['Period'])))
                    logs = logs[logs['Period'] == period]

                # create columns
                col1, col2, col3 = st.columns(3)

                # multiselect options
                with col1:
                    type = st.multiselect("Select Types", set(logs['Type']), default = set(logs['Type']))

                with col2:
                    source = st.multiselect("Select Sources", set(logs['Source']), default  = set(logs['Source']))  

                logs=logs[logs['Type'].isin(type) &
                        logs['Source'].isin(source)]
                
                # select date, time
                # check size
                if logs.shape[0]>0:  

                    # create columns
                    cols = st.columns([0.04,0.06,0.08,0.08,0.2, 0.54])

                    # Initialize date and time variables
                    start_date = logs['Date'].min()
                    end_date = logs['Date'].max()
                    start_time = time(0,0)
                    end_time = time(23,59)

                    if "start_time" not in st.session_state:
                        st.session_state.start_time = start_time 
                    if "end_time" not in st.session_state:
                        st.session_state.end_time = end_time 

                    # Buttons for preset date ranges
                    with cols[0]:
                        if st.button('All'):
                            start_date = logs['Date'].min()
                            end_date = logs['Date'].max()
                            st.session_state.start_time = time(0,0)
                            st.session_state.end_time = time(23,59)

                    with cols[1]:
                        if st.button('Today'):
                            start_date = datetime.today().date()
                            end_date = datetime.today().date()
                            st.session_state.start_time = time(0,0)
                            st.session_state.end_time = time(23,59)

                    with cols[2]:
                        if st.button('Yesterday'):
                            yesterday = datetime.today() - timedelta(days=1)
                            start_date = yesterday.date()
                            end_date = yesterday.date()
                            st.session_state.start_time = time(0,0)
                            st.session_state.end_time = time(23,59)

                    with cols[3]:
                        if st.button('This Week'):
                            start, end = get_current_week()
                            start_date = start.date()
                            end_date = end.date()
                            st.session_state.start_time = time(0,0)
                            st.session_state.end_time = time(23,59)

                    with cols[4]:
                        if st.button('Previous Week'):
                            start, end = get_previous_week()
                            start_date = start.date()
                            end_date = end.date()
                            st.session_state.start_time = time(0,0)
                            st.session_state.end_time = time(23,59)

                    col1, col2, col3 = st.columns([0.2,0.2,0.6])
                    
                    # Buttons to set date/time ranges
                    with col1:
                        start_date = st.date_input('Start Date', start_date)
                        end_date = st.date_input('End Date',end_date)
    
                    with col2:
                        start_time = st.time_input("Start Time:", key="start_time")
                        end_time = st.time_input("Start Time:", key="end_time")

                    # filter by time
                    logs = logs[
                        (logs['Date'].apply(lambda x: x.date()) >= start_date) &
                        (logs['Date'].apply(lambda x: x.date()) <= end_date) &
                        (logs['Time'] >= start_time) &
                        (logs['Time'] <= end_time) 
                        ]
                    
                    # check size
                    if logs.shape[0]>0:
                        # Combine 'date' and 'time' into a single 'datetime' column
                        logs['datetime'] = logs.apply(lambda row: pd.Timestamp.combine(row['Date'], row['Time']), axis=1)

                        # Sort by the new 'datetime' column
                        logs = logs.sort_values(by='datetime')

                        #  drop the 'datetime' column after sorting
                        logs = logs.drop(columns=['datetime'])

            # Display filtered dataframe
            st.write("## Fetched Data")
            # convert date to string format to get the same like in pandas
            logs['Date'] = logs['Date'].dt.strftime('%Y-%m-%d') 

            # Function to apply colors based on category
            def color_rows(row):
                color = None
                if row["Type"] == "Debug":
                    color = debug_color
                elif row["Type"] == "Position":
                    color = position_color
                elif row["Type"] == "Warning":
                    color = warning_color
                return ['' if col != 'Type' else f'background-color: {color}' if color else '' for col in row.index]
            
            # copy df
            logs_style=logs.copy(deep=True)

            # limit message size
            if use_limit_size:
                logs_style['Message'] = logs_style['Message'].apply(lambda x: (x[:message_limit] + '...') if isinstance(x, str) and len(x) > message_limit else x)

            # Apply the coloring function to the DataFrame
            logs_style = logs_style.style.apply(color_rows, axis=1)
            
            # Display the DataFrame with single-row selection enabled
            event = st.dataframe(data=logs_style,  on_select="rerun",selection_mode="single-row", use_container_width=True)
        
            # Display the selected row
            if use_limit_size:
                st.write("Selected row:")
                if logs.iloc[event.selection.rows]["Message"].to_string(index=False)!= "Series([], )":
                    st.info(logs.iloc[event.selection.rows]["Message"].to_string(index=False))
                else: 
                    st.info("")
    else:
        st.markdown("# Database don't exist.")