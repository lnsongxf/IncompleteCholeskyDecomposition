% ----------------------------------------------------------------------------------------------- %
% Solve Cholesky Decomposed Linear System Run Time Analysis
% Reference:
%   1. fd
% Remarks:
%   1.  Working on Float (Single).
% TODO:
%   1.  A
%   Release Notes:
%   -   1.0.000     10/07/2020  Royi Avital
%       *   First release version.
% ----------------------------------------------------------------------------------------------- %

%% Setting Environment Parameters

subStreamNumberDefault = 192;
run('InitScript.m');

generateFigures = ON;

figureIdx       = 0;
counterSpec     = '%04d';

funName = 'SolveCholsekyLinearSystemMex()';


%% Settings

vNumRows            = [100, 250, 500, 750, 1000, 1500, 2000, 2500]; %<! Goes out of memory for 3000
randDensity         = 0.000005; %<! Multiply it by (8 * vNumRows(end)^4) and make sure it is smaller

discardThr  = 1e-3;
shiftVal    = 0.001;
maxNumNz    = (vNumRows(end) * vNumRows(end)) ^ 2;

% Using numRows ^ 2 as 'gallery('poisson', numRows)' generates matrix of
% size numRows^2 * numRows^2.
hF = @(numRows) GenRandPdSparseMat(numRows ^ 2, randDensity); 

cSolver = {@(mL, vB) SolveCholsekyLinearSystemMex(mL, vB), ...
    @(mL, vB) mL.' \ (mL \ vB)};
cSolverString = {['MEX Cholesky'], ['MATLAB ''\\''']};
cMatrixGen = {@(numRows) gallery('poisson', numRows), @(numRows) gallery('tridiag', numRows ^ 2), @(numRows) GenWlsMatrix(numRows), hF};
cMatrixType = {['Poisson'], ['Tri Diagonal'], ['Weighted Least Squares (WLS)'], ['Random - ', num2str(randDensity)]};

numIterations = 3;



%% Generating Data



numDim = length(vNumRows);
numSolver = length(cSolver);
numMat = length(cMatrixGen);
vRunTime = zeros(numIterations, 1);
mRunTime = zeros(numDim, numSolver, numMat);

for ii = 1:numDim
    disp(['Working on Size: ', num2str(vNumRows(ii),'%05d')]);
    for kk = 1:numMat
        mA = cMatrixGen{kk}(vNumRows(ii));
        vB = randn(vNumRows(ii) * vNumRows(ii), 1);
        mL = ichol(mA);
        disp(['Working on Matrix Type: ', cMatrixType{kk}]);
        for jj = 1:numSolver
            disp(['Working on Solver #', num2str(jj,'%03d'), ' Out of #', num2str(numSolver, '%03d')]);
            for ll = 1:numIterations
                hRunTime = tic();
                vX = cSolver{jj}(mL, vB);
                vRunTime(ll) = toc(hRunTime);
                vX(1) = 1;
            end
            disp(['Finished in ', num2str(sum(vRunTime)), ' [Sec]']);
            mRunTime(ii, jj, kk) = min(vRunTime);
        end
    end
end


%% Display Results

figureIdx = figureIdx + 1;

hFigure = figure('Position', [100, 100, 800, 1200]);
for ii = 1:numMat
    hAxes = subplot(numMat, 1, ii);
    hLineSeris = plot(vNumRows .^ 2, mRunTime(:, :, ii));
    set(hLineSeris, 'LineWidth', 3);
    set(get(hAxes, 'Title'), 'String', {['Run Time for Matrix Type: ', cMatrixType{ii}]}, 'FontSize', 14);
    set(get(hAxes, 'XLabel'), 'String', ['Number of Rows'], 'FontSize', 12);
    set(get(hAxes, 'YLabel'), 'String', ['Run Time [Sec]'], 'FontSize', 12);
    legend(cSolverString);
end

if(generateFigures == ON)
    % saveas(hFigure,['Figure', num2str(figureIdx, figureCounterSpec), '.png']);
    print(hFigure, ['Figure', num2str(figureIdx, counterSpec), '.png'], '-dpng', '-r0'); %<! Saves as Screen Resolution
end


%% Auxiliary Functions

function [ mA ] = GenRandPdSparseMat( numRows, randDensity )

% mA  = sprandsym(numRows, randDensity, rand(numRows, 1)) + (5 * speye(numRows)); %<! Very slow!

% Roughly ensuring the diagonal element in each row is lkarger than the
% absolute sum of all other elements in the row
mA  = sprandsym(numRows, randDensity) + (numRows * speye(numRows));


end



%% Restore Defaults

% set(0, 'DefaultFigureWindowStyle', 'normal');
% set(0, 'DefaultAxesLooseInset', defaultLoosInset);

