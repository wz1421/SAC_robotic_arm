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


% --- Additional visualizations (written by Winnie) ---

% === Ball position density heatmap ===


% 1) Prepare data (numeric, finite, column vectors)
ballx = double(ballx(:));
bally = double(bally(:));
maskFinite = isfinite(ballx) & isfinite(bally);
ballxF = ballx(maskFinite);
ballyF = bally(maskFinite);
N = numel(ballxF);

if N < 5
    warning('Not enough samples to build a density map (N < 5). Skipping.');
    return
end

% 2) Plate/target/tolerance (try base workspace; provide fallbacks)
try
    plate = evalin('base','plate'); 
    W = plate.width;           % plate width (m), square plate in the example
catch
    if exist('platewidth','var') && ~isempty(platewidth)
        W = platewidth;
    else
        % Fallback: cover data extent with a margin
        W = 1.2 * max(range(ballxF), range(ballyF));
    end
end
xlimPlate = (W/2) * [-1 1];
ylimPlate = (W/2) * [-1 1];

try
    targetPos = evalin('base','targetPos'); 
    if isempty(targetPos), targetPos = [0 0]; end
catch
    targetPos = [0 0];
end

d_tol = 0.02;  % meters (adjust as needed)

% 3) Binning on fixed plate bounds (avoids auto edges that cause gaps)
nbx = 60; nby = 60;                % resolution of the heatmap
edgesX = linspace(xlimPlate(1), xlimPlate(2), nbx+1);
edgesY = linspace(ylimPlate(1), ylimPlate(2), nby+1);

[counts,~,~,binX,binY] = histcounts2(ballxF, ballyF, edgesX, edgesY);

% 4) Optional smoothing for nicer visuals (Image Processing Toolbox)
if exist('imgaussfilt','file')
    countsSm = imgaussfilt(counts, 1);  % sigma=1 bin
else
    countsSm = counts;
end

% 5) Choose normalization: 'count', 'prob', or 'time'
normMode = "time";  % set to "prob" or "count" if you prefer
switch normMode
    case "prob"
        Z = countsSm / max(1, N);             % p(x,y) = n_ij / N
        cbarLabel = 'Probability per bin';
    case "time"
        % Dwell time per bin in seconds if sample time is known
        try
            % Common names for sample time in base workspace
            Ts = evalin('base','Ts');        % try 'Ts' if defined
        catch
            Ts = []; 
        end
        if isempty(Ts)
            % If unknown, assume 0.02 s (50 Hz). Change to your sample time.
            Ts = 0.02; 
        end
        Z = countsSm * Ts;                    % seconds spent per bin
        cbarLabel = 'Dwell time per bin (s)';
    otherwise
        Z = countsSm;
        cbarLabel = 'Samples per bin';
end

% 6) Prepare grid for plotting and clip color range to 99th percentile
cx = (edgesX(1:end-1) + edgesX(2:end))/2;
cy = (edgesY(1:end-1) + edgesY(2:end))/2;
Zplot = Z';                                    % imagesc wants Y first (rows)
vmax = prctile(Zplot(:), 99); 
if isempty(vmax) || ~isfinite(vmax) || vmax <= 0
    vmax = max(Zplot(:));
end
if isempty(vmax) || ~isfinite(vmax) || vmax <= 0
    vmax = 1;  % safe fallback for empty/zero data
end

% 7) Plot
figDen = figure("Name","Ball Position Density");
imagesc(cx, cy, Zplot, [0 vmax]); axis xy; axis image; hold on;
colormap hot; cb = colorbar; ylabel(cb, cbarLabel);

% Plate outline (square example)
rectangle('Position', [xlimPlate(1) ylimPlate(1) W W],...
          'EdgeColor', [0.8 0.8 0.8], 'LineWidth', 1.2);

% Target and tolerance circle
plot(targetPos(1), targetPos(2), 'g*', 'MarkerSize', 8, 'LineWidth', 1.2);
rectangle('Position', [targetPos(1)-d_tol, targetPos(2)-d_tol, 2*d_tol, 2*d_tol],...
          'Curvature', [1 1], 'EdgeColor', [0.85 0.2 0.2], 'LineStyle', '--');

% Optional: overlay a lightly styled trajectory (subsample to reduce clutter)
skip = max(1, round(N/2000));                  % ~2000 points max
plot(ballxF(1:skip:end), ballyF(1:skip:end), '-',...
     'Color', [0.2 0.6 1.0], 'LineWidth', 0.5);

% Final cosmetics
xlim(xlimPlate); ylim(ylimPlate);
xlabel('X (m)'); ylabel('Y (m)');
title('Ball Position Density on Plate');
grid on

% Distance-to-target plot 
try
    obsTS = simOut.logsout.getElement("obs").Values;  % timeseries
    tRaw = obsTS.Time;
    if isduration(tRaw), time = seconds(tRaw); else, time = double(tRaw); end
    time = time(:);
    time = time(maskFinite); % align with filtered points

    % Get target position from base workspace, default to [0 0]
    try
        targetPos = evalin('base','targetPos');
        if isempty(targetPos), targetPos = [0 0]; end
    catch
        targetPos = [0 0];
    end

    if ~isempty(time) && numel(ballxF) == numel(time)
        p = [ballxF, ballyF];
        d = vecnorm(p - repmat(targetPos, size(p,1), 1), 2, 2);

        figDist = figure("Name","Distance to Target");
        plot(time, d, 'b-', 'LineWidth', 1.5); grid on;
        yline(0.02, 'r--', 'Tolerance'); 
        xlabel('Time (s)'); ylabel('Distance (m)');
        title('Distance to Target vs Time');

        RMSE = sqrt(mean(d.^2)); % RMSE = sqrt((1/T) * sum d(t)^2)
        fprintf('RMSE to target: %.6f m\n', RMSE);
    else
        warning('Time vector unavailable or length mismatch; skipping distance plot.');
    end
catch ME
    warning('Distance-to-target visualization failed: %s', ME.message);
end

obsTS = simOut.logsout.getElement("obs").Values;
obs    = obsTS.Data;
size(obs)            % should be [T x N]
class(obs)           % numeric
min(size(obs,2), 8)  % confirm you have columns 7 and 8

ballx = obs(:,7); bally = obs(:,8);
class(ballx), class(bally)
nnz(isfinite(ballx)), nnz(isfinite(bally))
unique(ballx(1:min(end,10)))  % quick peek at values
