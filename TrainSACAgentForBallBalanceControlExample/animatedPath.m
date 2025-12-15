function simOut = animatedPath(simOut)
% Animate the ball path on the plate

% Copyright 2021-2024, The MathWorks Inc.

persistent ax hball hpath ball radius plate platewidth

obs = simOut.logsout.getElement("obs").Values.Data;
ballx = obs(:,7);
bally = obs(:,8);
numSteps = numel(ballx);

if isempty(ax) || ~isvalid(ax)
    ball = evalin('base','ball');
    plate = evalin('base','plate');
    platewidth = plate.width;
    radius = ball.radius;

    fig = figure("Name","Ball Balance Animation", ...
        "NumberTitle","off", ...
        "MenuBar","none", ...
        "Position",[500,500,300,300]);
    set(fig,'Visible','on');
    ax = gca(fig);
    hold(ax,'on')
    title(ax,'Ball position on plate')
    xlabel(ax,'X (m)');
    ylabel(ax,'Y (m)');

    % plot plate
    rectangle(ax,"Position",platewidth*[-0.5,-0.5,1,1],"FaceColor","c");

    % plot ball path
    hpath = plot(ballx(1),bally(1),"b.");
    hpath.LineWidth=0.1;

    % plot ball
    hball = rectangle(ax, ...
        "Position", [ballx(1),bally(1),0,0] + 2*radius*[-0.5,-0.5,1,1], ...
        "Curvature", [1,1], ...
        "FaceColor","r");

    axis(ax,"equal");
    ax.XLim = 1.05 * platewidth * [-1,1];
    ax.YLim = 1.05 * platewidth * [-1,1];
    ax.Visible = true;
else
    hpath.XData = [];
    hpath.YData = [];
end

% Update ball position and path
for idx = 2:numSteps
    hpath.XData = [hpath.XData ballx(idx)];
    hpath.YData = [hpath.YData bally(idx)];
    hball.Position = [ballx(idx),bally(idx),0,0] + 2*radius*[-0.5,-0.5,1,1];
    drawnow();
end
