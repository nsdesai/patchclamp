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
    ax(1) = app.UIAxes;
    if DAQPARS.duration > 10000
        app.timescaleKnob.Value = '100000';
    elseif DAQPARS.duration > 1000
        app.timescaleKnob.Value = '10000';
    else
        app.timescaleKnob.Value = '1000';
    end
    app.startingtimeSlider.Limits = [0, DAQPARS.duration];
    pushValuesChangedButton(app);
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
    ax(2) = app.UIAxes;
    if DAQPARS.duration > 10000
        app.timescaleKnob.Value = '100000';
    elseif DAQPARS.duration > 1000
        app.timescaleKnob.Value = '10000';
    else
        app.timescaleKnob.Value = '1000';
    end
    app.startingtimeSlider.Limits = [0, DAQPARS.duration];
    pushValuesChangedButton(app);
    popup = true;
end
