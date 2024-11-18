% Gets selected climate data based on State, Division, or County
% Creates selected plots of the data

% The following can be set in a gui
File_Masks = {'climdiv-pcpncy*.txt',...  % 1: County Precipitation
              'climdiv-tmpccy*.txt',...  % 2: County Temperature
              'climdiv-pcpndv*.txt',...  % 3: State Division Precipitation
              'climdiv-tmpcdv*.txt',...  % 4: State Division Temperature
              'climdiv-pcpnst*.txt',...  % 5: State Precipitation
              'climdiv-tmpcst*.txt'};    % 6: State Temperature
          
Norm_Masks = {'climdiv-norm-pcpncy*.txt',... % 1: County Normal Precipitation
              'climdiv-norm-tmpccy*.txt',... % 2: County Normal Temperature
              'climdiv-norm-pcpndv*.txt',... % 3: State Division Normal Precipitation
              'climdiv-norm-tmpcdv*.txt',... % 4: State Division Normal Temperature
              'climdiv-norm-pcpnst*.txt',... % 5: State Normal Precipitation
              'climdiv-norm-tmpcst*.txt'};   % 6: State Normal Temperature 
          
% Element Codes:
%   01: Precipitation
%   02: Average Temperature
%   05: PDSI
%   06: PHDI
%   07: ZNDX
%   08: PMDI
%   25: Heating Degree Days
%   26: Cooling Degree Days
%   27: Maximum Temperature
%   28: Minimum Temperature
%   and there are more
Element_Code_Str = {'Precipitation','Temperature'};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SELECT ELEMENT CODE %%%%%%%%%%%%%%%%%%%%%
Element_Code = 2;
str1 = sprintf('Data Type: %s',string(Element_Code_Str(Element_Code)));
disp(str1);

% File Codes:
%   1:  County
%   2:  State Division
%   3:  State
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SELECT FILE CODE %%%%%%%%%%%%%%%%%%%%%%%%
File_Code_Str = {'County','State Division','State'};
File_Code = 1;
str1 = sprintf('File Type: %s',string(File_Code_Str(File_Code)));
disp(str1);

% Header Info:
% County File
%   Name   Position
%   State-Code      1-2 (Michigan - 20)
%   County FIPS     3-5 (Ottawa - 139)
%   Element Code    6-7 (Temperature - 02)
%   Year            8-11 
% State Division File
%   Name   Position
%   State-Code      1-2 (Michigan - 20)
%   Division        3-4 (West Central Lower - 5)
%   Element Code    5-6 (Temperature - 02)
%   Year            7-10 
% State File
%   Name   Position
%   State-Code      1-3 (Michigan - 020)
%   Division        4   (Always 0)
%   Element Code    5-6 (Temperature - 02)
%   Year            7-10 


if Element_Code == 1        % Precipitation
    MissingValueCode = -9.99;
    if File_Code == 1       % County
        fmask = File_Masks(1);
        nmask = Norm_Masks(1);
        SearchValue = uint64(20139010000);  % State = 20, County = 139, date type = 01, first year = 0000
    elseif File_Code == 2   % State Divisions
        fmask = File_Masks(3);
        nmask = Norm_Masks(3);
        SearchValue = uint64(2005010000);  % State = 20, Division = 05, date type = 01, first year = 0000
    else                    % State
        fmask = File_Masks(5);
        nmask = Norm_Masks(5);
        SearchValue = uint64(0200010000);  % State = 020, Division = 0, date type = 01, first year = 0000
    end
elseif Element_Code == 2    % Temperature
    MissingValueCode = -99.9;
    if File_Code == 1       % County
        fmask = File_Masks(2);
        nmask = Norm_Masks(2);
        SearchValue = uint64(20139020000);  % State = 20, County = 139, date type = 02, first year = 0000
    elseif File_Code == 2   % State Divisions
        fmask = File_Masks(4);
        nmask = Norm_Masks(4);
        SearchValue = uint64(2005020000);  % State = 20, Division = 05, date type = 02, first year = 0000
    else                    % State
        fmask = File_Masks(6);
        nmask = Norm_Masks(6);
        SearchValue = uint64(0200020000);  % State = 020, Division = 0, date type = 02, first year = 0000
    end
end

% fname = uigetfile(fmask);
folderpath = cd;
flist = dir(fullfile(folderpath,string(fmask)));
% find newest file
[~, idx] = sort([flist.datenum], 'descend');
fname = flist(idx(1)).name;
% Read entire data file
str1 = sprintf('Opening Data File:     %s', fname);
disp(str1);
FullData = readtable(num2str(fname),'Format','%u64%f%f%f%f%f%f%f%f%f%f%f%f');
% Find all rows with correct state,county,data type
RowStart = find(FullData.Var1 >= SearchValue,1);
RowEnd = find(FullData.Var1 >= SearchValue+9999,1)-1;

% Create a structure with data from the desired location, then clear the large
% table
Header = FullData{RowStart:RowEnd,1};
Data.Year = Header - 10000 * (Header/10000);
Data.Values = FullData{RowStart:RowEnd,2:13};
clear FullData Header;

NormalTimePeriods = {'Base Period 1901-1938',... % 1
                     'Base Period 1911-1940',... % 2
                     'Base Period 1921-1950',... % 3
                     'Base Period 1931-1960',... % 4
                     'Base Period 1941-1970',... % 5
                     'Base Period 1951-1980',... % 6
                     'Base Period 1961-1990',... % 7
                     'Base Period 1971-2000',... % 8
                     'Base Period 1981-2010',... % 9
                     'Base Period 1991-2020',... % 10
                     'Base Period 1901-2000',... % 31    This one seems to be the standard
                     'Base Period 1895-2020'};   % 32

NormalTimePeriod = 31;
if NormalTimePeriod <= 10
    TimeIdx = NormalTimePeriod;
elseif NormalTimePeriod >= 31
    TimeIdx = NormalTimePeriod - 20;
end
BaseStr = NormalTimePeriods(TimeIdx);
SearchValue = SearchValue + NormalTimePeriod;
% Read entire normal file
nlist = dir(fullfile(folderpath,string(nmask)));
% find newest file
[~, idx] = sort([nlist.datenum], 'descend');
nname = nlist(idx(1)).name;
% nname = uigetfile(nmask);
str2 = sprintf('Opening Baseline File: %s', nname);
disp(str2);
FullNormData = readtable(num2str(nname),'Format','%u64%f%f%f%f%f%f%f%f%f%f%f%f');
% Find all rows with correct state,county,data type
RowStart = find(FullNormData.Var1 >= SearchValue,1);
Data.NormBaseline = FullNormData{RowStart,2:13};
clear FullNormData RowStart RowEnd SearchValue

% Calculate Anomaly = Ave Value - Baseline
TotalRows = size(Data.Values,1);
for y = 1:TotalRows
    Data.Anomaly(y,:) = Data.Values(y,:) - Data.NormBaseline(1,:);
end
%%
% Use missing data code to set last valid column in final row. 
LastFullRow = TotalRows;
LastRowSize = 0;
for m = 1:12
    RowStart(m) = 1;
    RowEnd(m) = TotalRows;
    if Data.Values(end,m) == MissingValueCode
        Data.Anomaly(end,m) = MissingValueCode;
        LastFullRow = TotalRows - 1;
        RowEnd(m) = LastFullRow;
    else
        LastRowSize = LastRowSize + 1;
    end
end

% Apply 5 year mean filter to Temperature and Anomaly
for m = 1:12
    for y = RowStart(m):RowEnd(m)
        if y < RowStart(m) + 4
            Data.ValuesFiltered(y,m) = Data.Values(y,m);
            Data.AnomalyFiltered(y,m) = Data.Anomaly(y,m);
        else
            Data.ValuesFiltered(y,m) = mean(Data.Values(y-4:y,m));
            Data.AnomalyFiltered(y,m) = mean(Data.Anomaly(y-4:y,m));
        end
    end
end

% Calculate average temperature anomaly for combined months
for y = 1:LastFullRow
    Data.CombinedMonths(y) = mean(Data.Anomaly(y,:));
    Data.CombinedMonthsFiltered(y) = mean(Data.AnomalyFiltered(y,:));
end

% Calculate Average for each month
for m = 1:12
    Data.MonthlyAverageValues(m) = mean(Data.Values(:,m));
end
%%
%%%%%%%%%%%%%%%%%%% PLOTTING SECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Mstr = ["January","February","March","April","May","June","July","August","September","October","November","December"];
PrecipStr = '''Ave Precip'', ';
FiltStr = '''5 Year Mean'', ';
LocStr = ' ,''Location'', ';
BestStr = '''best''';

for m = 1:12
    i1 = RowStart(m);
    i2 = RowEnd(m);

    figure;
    plot(Data.Year(i1:i2),Data.Values(i1:i2,m),'-r','Marker','.');
    hold on;
    plot(Data.Year(i1:i2),Data.ValuesFiltered(i1:i2,m),'-b','LineWidth',2);
    yline(Data.NormBaseline(m));
    grid on;
    axis tight;
    if Element_Code == 1
        lg = legend('Mean Precip','5 Year Mean','Location','best');
        lg.Title.String = BaseStr;
        ylabel('Inches');
        if File_Code == 1
            Tstr = sprintf('Ottawa County Average Precipitation for %s', Mstr(m));
            Fstr = sprintf('Ottawa_Precip_%s.png',Mstr(m));
        elseif File_Code == 2
            Tstr = sprintf('MI Division 5 Average Precipitation for %s', Mstr(m));
            Fstr = sprintf('MI_Div5_Precip_%s.png',Mstr(m));
        else
            Tstr = sprintf('MI Average Precipitation for %s', Mstr(m));
            Fstr = sprintf('MI_Precip_%s.png',Mstr(m));
        end
    else
        lg = legend('Mean Temp','5 Year Mean','Location','best');
        lg.Title.String = BaseStr;
        ylabel('Degrees F');
        if File_Code == 1
            Tstr = sprintf('Ottawa County Average Temperature for %s', Mstr(m));
            Fstr = sprintf('Ottawa_Temp_%s.png',Mstr(m));
        elseif File_Code == 2
            Tstr = sprintf('MI Division 5 Average Temperature for %s', Mstr(m));
            Fstr = sprintf('MI_Div5_Temp_%s.png',Mstr(m));
        else
            Tstr = sprintf('MI Average Temperature for %s', Mstr(m));
            Fstr = sprintf('MI_Temp_%s.png',Mstr(m));
        end
    end
    title(Tstr);
    xlabel('Year');
    saveas(gcf,Fstr);

    figure;
    plot(Data.Year(i1:i2),Data.Anomaly(i1:i2,m),'-r','Marker','.');
    hold on;
    plot(Data.Year(i1:i2),Data.AnomalyFiltered(i1:i2,m),'-b','LineWidth',2);
    yline(0);
    grid on;
    axis tight;
    if Element_Code == 1
        if File_Code == 1
            Tstr = sprintf('Ottawa County Precipitation Anomaly for %s', Mstr(m));
            Fstr = sprintf('Ottawa_Precip_Anomaly_%s.png',Mstr(m));
            TMstr = sprintf('Ottawa County Precipitation Anomaly');
            FMstr = sprintf('Ottawa_Precip_Monthly_Anomaly_%s.png',Mstr(m));
        elseif File_Code == 2
            Tstr = sprintf('MI Division 5 Precipitation Anomaly for %s', Mstr(m));
            Fstr = sprintf('MI_Div_5_Precip_Anomaly_%s.png',Mstr(m));
            TMstr = sprintf('MI Divison 5 Precipitation Anomaly');
            FMstr = sprintf('MI_Div_5_Precip_Monthly_Anomaly_%s.png',Mstr(m));
        else
            Tstr = sprintf('MI Precipitation Anomaly for %s', Mstr(m));
            Fstr = sprintf('MI_Precip_Anomaly_%s.png',Mstr(m));
            TMstr = sprintf('MI Precipitation Anomaly');
            Fstr = sprintf('MI_Precip_Monthly_Anomaly_%s.png',Mstr(m));
        end
        ylabel('Inches');
    else
        if File_Code == 1
            Tstr = sprintf('Ottawa County Temperature Anomaly for %s', Mstr(m));
            Fstr = sprintf('Ottawa_Temp_Anomaly_%s.png',Mstr(m));
            TMstr = sprintf('Ottawa County Temperature Anomaly');
            FMstr = sprintf('Ottawa_Temp_Monthly_Anomaly_%s.png',Mstr(m));
        elseif File_Code == 2
            Tstr = sprintf('MI Division 5 Temperature Anomaly for %s', Mstr(m));
            Fstr = sprintf('MI_Div_5_Temp_Anomaly_%s.png',Mstr(m));
            TMstr = sprintf('MI Division 5 Temperature Anomaly');
            FMstr = sprintf('MI_Div_5_Temp_Monthly_Anomaly_%s.png',Mstr(m));
        else
            Tstr = sprintf('MI Temperature Anomaly for %s', Mstr(m));
            Fstr = sprintf('MI_Temp_Anomaly_%s.png',Mstr(m));
            TMstr = sprintf('MI Temperature Anomaly');
            FMstr = sprintf('MI_Temp_Monthly_Anomaly_%s.png',Mstr(m));
        end
        ylabel('Degrees F');
    end
    title(Tstr);
    legend('Anomaly','5 Year Mean','Location','best');
    xlabel('Year');
    saveas(gcf,Fstr);
end

%%
figure;
plot(Data.Values(LastFullRow,:) - Data.MonthlyAverageValues,'.-b');
hold on;
plot(Data.Values(TotalRows,1:LastRowSize) - Data.MonthlyAverageValues(1:LastRowSize),'.-r');
% Set x-axis labels to month names
set(gca, 'xtick', 1:12, 'xticklabel', {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'});
grid on;
axis tight;
ylabel('Temperature Degrees F');
xlabel('Month');
title(TMstr);
yline(0,'k', 'LineWidth',2);
labels = {string(Data.Year(LastFullRow)), string(Data.Year(TotalRows)),'Baseline'};
legend(labels,'Location','Best');
saveas(gcf,FMstr);
%%
i = LastFullRow;

figure;
plot(Data.Year(1:i),Data.CombinedMonths(1:i),'-r','Marker','.');
hold on;
plot(Data.Year(1:i),Data.CombinedMonthsFiltered(1:i),'-b','LineWidth',2);
yline(0);
grid on;
axis tight;
if Element_Code == 1
    if File_Code == 1
        Tstr = sprintf('Ottawa County Yearly Precipitation Anomaly');
    elseif File_Code == 2
        Tstr = sprintf('MI Division 5 Yearly Precipitation Anomaly');
    else
        Tstr = sprintf('MI Yearly Precipitation Anomaly');
    end
    ylabel('Inches');
else
    if File_Code == 1
        Tstr = sprintf('Ottawa County Yearly Temperature Anomaly');
    elseif File_Code == 2
        Tstr = sprintf('MI Division 5 Yearly Temperature Anomaly');
    else
        Tstr = sprintf('MI Yearly Temperature Anomaly');
    end
    ylabel('Degrees F');
end
title(Tstr);
legend('Mean Anomaly','5 Year Mean','Location','best');
xlabel('Year');
saveas(gcf,Fstr);
