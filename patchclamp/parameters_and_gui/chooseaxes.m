function [ax,popup] = chooseaxes(ax1)
global DAQPARS

ax = [DAQPARS.MainApp.UIInputAxes1, DAQPARS.MainApp.UIInputAxes2];
popup = false;

% graph1 app
if strcmp(DAQPARS.MainApp.popupSwitch_1.Value,'On') && ~isempty(find(ax1==1, 1))
    foo = findobj('Tag','graph1');
    if numel(foo)>1
        for ii = numel(foo):-1:2
            delete(foo(ii));
        end
    end
    if isempty(foo)
        app = graph1;
    else
        app = foo.RunningAppInstance;
    end
    setScales(app)

    app.experimentEditField.Value = num2str(DAQPARS.experimentNo,'%03i');
    app.trialEditField.Value = num2str(DAQPARS.trialNo,'%03i');
    ax(1) = app.UIAxes;
    popup = true;
end

% graph2 app
if strcmp(DAQPARS.MainApp.popupSwitch_2.Value,'On') && ~isempty(find(ax1==2, 1))
    foo = findobj('Tag','graph2');
    if numel(foo)>1
        for ii = numel(foo):-1:2
            delete(foo(ii));
        end
    end
    if isempty(foo)
        app = graph2;
    else
        app = foo.RunningAppInstance;
    end
    setScales(app)
    
    app.experimentEditField.Value = num2str(DAQPARS.experimentNo,'%03i');
    app.trialEditField.Value = num2str(DAQPARS.trialNo,'%03i');
    ax(2) = app.UIAxes;
    popup = true;
end
