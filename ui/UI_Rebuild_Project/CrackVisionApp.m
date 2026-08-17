classdef CrackVisionApp < handle
    % CrackVisionApp  Programmatic shell for the rebuilt ELEC9773 UI.

    properties (Access = private)
        UIFigure
        RootGrid
        HeaderPanel
        HeaderGrid
        ModePanel
        ModeGrid
        ContentGrid
        WorkflowPanel
        WorkflowGrid
        WorkspacePanel
        WorkspaceGrid
        EvaluationGrid
        FocusAxes
        ViewControlGrid
        InsightPanel
        InsightGrid
        AnnotationGrid
        AnnotationAxes
        AnnotationControlGrid
        AnnotationInsightGrid
        StatisticsGrid
        StatisticsComparisonAxes
        StatisticsInsightGrid
        StatisticsCardsGrid
        StatisticsAnalysedValueLabel
        StatisticsGTValueLabel
        StatisticsDLF1ValueLabel
        StatisticsClassicalF1ValueLabel
        StatisticsDLTimeValueLabel
        StatisticsCaseTable
        StatisticsCaseImageIndices = zeros(0, 1)

        AppTitleLabel
        AppSubtitleLabel
        ModelStatusLabel
        DeviceStatusLabel
        OpenImageButton
        OpenFolderButton
        ExportButton

        AnalyseModeButton
        AnnotateModeButton
        StatisticsModeButton

        InputSectionLabel
        LoadGroundTruthButton
        ClearAllButton
        AnalysisSectionLabel
        AnalyseImageButton
        FolderSectionLabel
        PreviousImageButton
        ImagePositionField
        ImageCountLabel
        NextImageButton
        PauseAnalysisButton
        AnalysisProgressTrack
        AnalysisProgressFill
        AnalysisProgressLabel
        ImageListBox

        OriginalAxes
        GroundTruthAxes
        AIPredictionAxes
        AIOverlayAxes
        ClassicalPredictionAxes
        ClassicalOverlayAxes
        SixPanelViewButton
        FocusViewButton
        OverlayOpacityLabel
        OverlayOpacitySlider

        InsightTitleLabel
        EvaluationMetricsTable
        ThresholdSlider
        ThresholdValueLabel
        ResetConfigurationButton
        ReloadModelButton
        ConfigurationStatusLabel
        OverlayLegendPanel

        DrawCrackButton
        EraseCrackButton
        AnnotationBrushSlider
        AnnotationBrushValueLabel
        UndoAnnotationButton
        ClearAnnotationButton
        SaveAnnotationButton
        CompareAnnotationButton
        AnnotationCoverageLabel
        AnnotationStrokeLabel
        AnnotationMetricsTable
        AnnotationImageHandle
        AnnotationZoomOutButton
        AnnotationZoomInButton
        AnnotationZoomResetButton
        AnnotationZoomValueLabel

        StatisticsBatchLabel
        StatisticsMetricsTable
        StatisticsRefreshButton

        OriginalImage = []
        GroundTruthMask = []
        AIProbabilityMap = []
        AIPredictionMask = []
        PerModelProbabilityMaps = struct()
        AIElapsedSeconds = NaN
        AIInferenceMode = ""
        AITileGrid = [1 1]
        ClassicalPredictionMask = []
        ClassicalElapsedSeconds = NaN
        ManualReferenceMask = []
        AnnotationHistory = cell(0, 1)
        AnnotationStrokeCount = 0
        AnnotationBrushWidth = 7
        AnnotationTool = "draw"
        AnnotationDrawing = false
        AnnotationLastPoint = []
        AnnotationZoomLevels = [1 1.5 2 3 4 6 8]
        AnnotationZoomIndex = 1
        CurrentImagePath = ""
        ImageFiles = strings(0, 1)
        GroundTruthFiles = strings(0, 1)
        CurrentImageIndex = 0
        CurrentFolderPath = ""
        PairingMode = "Images only"
        CachedAIProbabilityMaps = cell(0, 1)
        CachedAIElapsedSeconds = zeros(0, 1)
        CachedAIInferenceModes = strings(0, 1)
        CachedAITileGrids = zeros(0, 2)
        CachedClassicalPredictionMasks = cell(0, 1)
        CachedClassicalElapsedSeconds = zeros(0, 1)
        CachedManualReferenceMasks = cell(0, 1)
        CachedAnnotationStrokeCounts = zeros(0, 1)
        AnalysisCompleted = false(0, 1)
        BatchAnalysisRunning = false
        BatchPauseRequested = false
        GroundTruthLoaded = false
        CurrentThreshold = 0.33
        CurrentModelWeights = [0.660 0.102 0.102 0.136]
        OverlayOpacity = 0.55
        FocusedViewName = ""
        CurrentMode = "Analyse"
    end

    methods
        function app = CrackVisionApp
            try
                app.createComponents();
                app.setMode("Analyse");
                app.UIFigure.Visible = "on";
            catch errorInfo
                if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                    delete(app.UIFigure);
                end
                rethrow(errorInfo);
            end
        end

        function delete(app)
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end
    end

    methods (Access = private)
        function createComponents(app)
            app.UIFigure = uifigure( ...
                "Visible", "off", ...
                "Name", "CrackVision", ...
                "Color", [0.96 0.97 0.98], ...
                "Position", [80 60 1600 900]);

            app.RootGrid = uigridlayout(app.UIFigure, [3 1]);
            app.RootGrid.RowHeight = {56, 44, "1x"};
            app.RootGrid.ColumnWidth = {"1x"};
            app.RootGrid.Padding = [12 10 12 12];
            app.RootGrid.RowSpacing = 8;

            app.createHeader();
            app.createModeBar();
            app.createContentShell();
            app.createWorkflow();
            app.createAnalyseWorkspace();
            app.createInsightPanel();
            app.createAnnotationWorkspace();
            app.createStatisticsWorkspace();
            drawnow;
            app.resizeStatisticsCaseColumns();
        end

        function createHeader(app)
            app.HeaderPanel = uipanel(app.RootGrid, ...
                "BorderType", "none", "BackgroundColor", [1 1 1]);
            app.HeaderPanel.Layout.Row = 1;

            app.HeaderGrid = uigridlayout(app.HeaderPanel, [2 6]);
            app.HeaderGrid.RowHeight = {30, 20};
            app.HeaderGrid.ColumnWidth = {330, "1x", 220, 110, 110, 90};
            app.HeaderGrid.Padding = [14 3 10 3];
            app.HeaderGrid.ColumnSpacing = 8;
            app.HeaderGrid.RowSpacing = 0;

            app.AppTitleLabel = uilabel(app.HeaderGrid, ...
                "Text", "CrackVision", ...
                "FontSize", 22, ...
                "FontWeight", "bold", ...
                "FontColor", [0.08 0.36 0.72]);
            app.AppTitleLabel.Layout.Row = 1;
            app.AppTitleLabel.Layout.Column = 1;

            app.AppSubtitleLabel = uilabel(app.HeaderGrid, ...
                "Text", "Deep-learning road crack analysis", ...
                "FontSize", 11, ...
                "FontColor", [0.35 0.39 0.45]);
            app.AppSubtitleLabel.Layout.Row = 2;
            app.AppSubtitleLabel.Layout.Column = 1;

            app.ModelStatusLabel = uilabel(app.HeaderGrid, ...
                "Text", "Final Ensemble · Not loaded", ...
                "HorizontalAlignment", "right", ...
                "FontWeight", "bold", ...
                "FontColor", [0.20 0.23 0.28]);
            app.ModelStatusLabel.Layout.Row = 1;
            app.ModelStatusLabel.Layout.Column = 3;

            app.DeviceStatusLabel = uilabel(app.HeaderGrid, ...
                "Text", "Device: Auto", ...
                "HorizontalAlignment", "right", ...
                "FontColor", [0.42 0.45 0.50]);
            app.DeviceStatusLabel.Layout.Row = 2;
            app.DeviceStatusLabel.Layout.Column = 3;

            app.OpenImageButton = uibutton(app.HeaderGrid, "push", ...
                "Text", "Open Image", ...
                "FontWeight", "bold", ...
                "ButtonPushedFcn", @(~, ~) app.openImage());
            app.OpenImageButton.Layout.Row = [1 2];
            app.OpenImageButton.Layout.Column = 4;

            app.OpenFolderButton = uibutton(app.HeaderGrid, "push", ...
                "Text", "Open Folder", ...
                "FontWeight", "bold", ...
                "ButtonPushedFcn", @(~, ~) app.openImageFolder());
            app.OpenFolderButton.Layout.Row = [1 2];
            app.OpenFolderButton.Layout.Column = 5;

            app.ExportButton = uibutton(app.HeaderGrid, "push", ...
                "Text", "Export", ...
                "Enable", "off", ...
                "ButtonPushedFcn", @(~, ~) app.exportCurrentResult());
            app.ExportButton.Layout.Row = [1 2];
            app.ExportButton.Layout.Column = 6;
        end

        function createModeBar(app)
            app.ModePanel = uipanel(app.RootGrid, ...
                "BorderType", "none", "BackgroundColor", [0.96 0.97 0.99]);
            app.ModePanel.Layout.Row = 2;

            app.ModeGrid = uigridlayout(app.ModePanel, [1 4]);
            app.ModeGrid.RowHeight = {"1x"};
            app.ModeGrid.ColumnWidth = {110, 110, 110, "1x"};
            app.ModeGrid.Padding = [8 4 8 4];
            app.ModeGrid.ColumnSpacing = 6;

            app.AnalyseModeButton = uibutton(app.ModeGrid, "push", ...
                "Text", "Analyse", ...
                "ButtonPushedFcn", @(~, ~) app.setMode("Analyse"));
            app.AnalyseModeButton.Layout.Column = 1;

            app.AnnotateModeButton = uibutton(app.ModeGrid, "push", ...
                "Text", "Annotate", ...
                "ButtonPushedFcn", @(~, ~) app.setMode("Annotate"));
            app.AnnotateModeButton.Layout.Column = 2;

            app.StatisticsModeButton = uibutton(app.ModeGrid, "push", ...
                "Text", "Statistics", ...
                "ButtonPushedFcn", @(~, ~) app.setMode("Statistics"));
            app.StatisticsModeButton.Layout.Column = 3;
        end

        function createContentShell(app)
            app.ContentGrid = uigridlayout(app.RootGrid, [1 3]);
            app.ContentGrid.Layout.Row = 3;
            app.ContentGrid.ColumnWidth = {190, "1x", 290};
            app.ContentGrid.RowHeight = {"1x"};
            app.ContentGrid.Padding = [0 0 0 0];
            app.ContentGrid.ColumnSpacing = 10;

            app.WorkflowPanel = uipanel(app.ContentGrid, ...
                "Title", "", "BackgroundColor", [0.97 0.97 0.98]);
            app.WorkflowPanel.Layout.Column = 1;

            app.WorkspacePanel = uipanel(app.ContentGrid, ...
                "Title", "", "BackgroundColor", [1 1 1]);
            app.WorkspacePanel.Layout.Column = 2;

            app.InsightPanel = uipanel(app.ContentGrid, ...
                "Title", "", "BackgroundColor", [0.97 0.97 0.98]);
            app.InsightPanel.Layout.Column = 3;
        end

        function createWorkflow(app)
            app.WorkflowGrid = uigridlayout(app.WorkflowPanel, [14 1]);
            app.WorkflowGrid.RowHeight = {28, 38, 38, 28, 44, 38, 18, ...
                22, 38, 12, 28, 38, 28, "1x"};
            app.WorkflowGrid.ColumnWidth = {"1x"};
            app.WorkflowGrid.Padding = [12 14 12 12];
            app.WorkflowGrid.RowSpacing = 8;

            app.InputSectionLabel = app.makeSectionLabel(app.WorkflowGrid, "REFERENCE", 1);

            app.LoadGroundTruthButton = uibutton(app.WorkflowGrid, "push", ...
                "Text", "Load Ground Truth", ...
                "ButtonPushedFcn", @(~, ~) app.openGroundTruth());
            app.LoadGroundTruthButton.Layout.Row = 2;

            app.ClearAllButton = uibutton(app.WorkflowGrid, "push", ...
                "Text", "Clear", ...
                "Tooltip", "Clear all loaded images, masks, predictions and cached results.", ...
                "ButtonPushedFcn", @(~, ~) app.clearAllImages());
            app.ClearAllButton.Layout.Row = 3;

            app.AnalysisSectionLabel = app.makeSectionLabel(app.WorkflowGrid, "ANALYSIS", 4);

            app.AnalyseImageButton = uibutton(app.WorkflowGrid, "push", ...
                "Text", "Analyse Image", ...
                "FontSize", 14, ...
                "FontWeight", "bold", ...
                "BackgroundColor", [0.08 0.36 0.72], ...
                "FontColor", [1 1 1], ...
                "Enable", "off", ...
                "ButtonPushedFcn", @(~, ~) app.runAIAnalysis());
            app.AnalyseImageButton.Layout.Row = 5;

            app.PauseAnalysisButton = uibutton(app.WorkflowGrid, "push", ...
                "Text", "Pause", ...
                "Enable", "off", ...
                "ButtonPushedFcn", @(~, ~) app.toggleFolderPause());
            app.PauseAnalysisButton.Layout.Row = 6;

            app.AnalysisProgressTrack = uipanel(app.WorkflowGrid, ...
                "BorderType", "none", ...
                "BackgroundColor", [0.84 0.87 0.91]);
            app.AnalysisProgressTrack.Layout.Row = 7;
            app.AnalysisProgressFill = uipanel( ...
                app.AnalysisProgressTrack, ...
                "BorderType", "none", ...
                "BackgroundColor", [0.08 0.46 0.86], ...
                "Visible", "off", ...
                "Position", [0 0 1 18]);

            app.AnalysisProgressLabel = uilabel(app.WorkflowGrid, ...
                "Text", "0%", ...
                "HorizontalAlignment", "center", ...
                "FontColor", [0.42 0.45 0.50]);
            app.AnalysisProgressLabel.Layout.Row = 8;

            app.ReloadModelButton = uibutton(app.WorkflowGrid, "push", ...
                "Text", "Reload Model", ...
                "Tooltip", "Clear the in-memory networks and reload them on the next analysis.", ...
                "ButtonPushedFcn", @(~, ~) app.requestModelReload());
            app.ReloadModelButton.Layout.Row = 9;

            app.FolderSectionLabel = app.makeSectionLabel(app.WorkflowGrid, "FOLDER", 11);

            navigationGrid = uigridlayout(app.WorkflowGrid, [1 4]);
            navigationGrid.Layout.Row = 12;
            navigationGrid.ColumnWidth = {32, 52, "1x", 32};
            navigationGrid.RowHeight = {"1x"};
            navigationGrid.Padding = [0 0 0 0];
            navigationGrid.ColumnSpacing = 5;

            app.PreviousImageButton = uibutton(navigationGrid, "push", ...
                "Text", "<", ...
                "Enable", "off", ...
                "ButtonPushedFcn", @(~, ~) app.showPreviousImage());
            app.PreviousImageButton.Layout.Column = 1;

            app.ImagePositionField = uieditfield(navigationGrid, "numeric", ...
                "Value", 1, ...
                "Limits", [1 Inf], ...
                "RoundFractionalValues", "on", ...
                "HorizontalAlignment", "center", ...
                "Enable", "off", ...
                "ValueChangedFcn", @(src, ~) app.jumpToImage(src.Value));
            app.ImagePositionField.Layout.Column = 2;

            app.ImageCountLabel = uilabel(navigationGrid, ...
                "Text", "/ 0", ...
                "HorizontalAlignment", "left", ...
                "FontColor", [0.42 0.45 0.50]);
            app.ImageCountLabel.Layout.Column = 3;

            app.NextImageButton = uibutton(navigationGrid, "push", ...
                "Text", ">", ...
                "Enable", "off", ...
                "ButtonPushedFcn", @(~, ~) app.showNextImage());
            app.NextImageButton.Layout.Column = 4;

            hintLabel = uilabel(app.WorkflowGrid, ...
                "Text", "Select an image", ...
                "FontSize", 11, ...
                "FontColor", [0.42 0.45 0.50], ...
                "FontWeight", "bold", ...
                "HorizontalAlignment", "left");
            hintLabel.Layout.Row = 13;

            app.ImageListBox = uilistbox(app.WorkflowGrid, ...
                "Items", {'No images loaded'}, ...
                "ItemsData", 0, ...
                "Value", 0, ...
                "Enable", "off", ...
                "ValueChangedFcn", @(source, ~) ...
                    app.jumpToImage(source.Value));
            app.ImageListBox.Layout.Row = 14;
        end

        function createAnalyseWorkspace(app)
            app.WorkspaceGrid = uigridlayout(app.WorkspacePanel, [2 1]);
            app.WorkspaceGrid.RowHeight = {"1x", 42};
            app.WorkspaceGrid.ColumnWidth = {"1x"};
            app.WorkspaceGrid.Padding = [12 12 12 8];
            app.WorkspaceGrid.RowSpacing = 8;

            app.EvaluationGrid = uigridlayout(app.WorkspaceGrid, [2 3]);
            app.EvaluationGrid.Layout.Row = 1;
            app.EvaluationGrid.RowHeight = {"1x", "1x"};
            app.EvaluationGrid.ColumnWidth = {"1x", "1x", "1x"};
            app.EvaluationGrid.Padding = [0 0 0 0];
            app.EvaluationGrid.RowSpacing = 10;
            app.EvaluationGrid.ColumnSpacing = 10;

            app.OriginalAxes = app.makeResultAxes(app.EvaluationGrid, "Original", 1, 1);
            app.ClassicalPredictionAxes = app.makeResultAxes(app.EvaluationGrid, "Classical Prediction", 1, 2);
            app.AIPredictionAxes = app.makeResultAxes(app.EvaluationGrid, "DL Prediction", 1, 3);
            app.GroundTruthAxes = app.makeResultAxes(app.EvaluationGrid, "Ground Truth", 2, 1);
            app.ClassicalOverlayAxes = app.makeResultAxes(app.EvaluationGrid, "Classical Overlay", 2, 2);
            app.AIOverlayAxes = app.makeResultAxes(app.EvaluationGrid, "DL Overlay", 2, 3);

            app.FocusAxes = uiaxes(app.WorkspaceGrid);
            app.FocusAxes.Layout.Row = 1;
            app.FocusAxes.XTick = [];
            app.FocusAxes.YTick = [];
            app.FocusAxes.Box = "on";
            app.FocusAxes.Color = [0.975 0.98 0.985];
            app.FocusAxes.Toolbar.Visible = "off";
            app.FocusAxes.Visible = "off";

            app.ViewControlGrid = uigridlayout(app.WorkspaceGrid, [1 5]);
            app.ViewControlGrid.Layout.Row = 2;
            app.ViewControlGrid.RowHeight = {"1x"};
            app.ViewControlGrid.ColumnWidth = {110, 100, "1x", 110, 170};
            app.ViewControlGrid.Padding = [0 0 0 0];
            app.ViewControlGrid.ColumnSpacing = 8;

            app.SixPanelViewButton = uibutton(app.ViewControlGrid, "push", ...
                "Text", "Six-panel View", ...
                "FontWeight", "bold", ...
                "BackgroundColor", [0.88 0.93 0.99], ...
                "ButtonPushedFcn", @(~, ~) app.showSixPanelView());
            app.SixPanelViewButton.Layout.Column = 1;

            app.FocusViewButton = uibutton(app.ViewControlGrid, "push", ...
                "Text", "Focus View", ...
                "Enable", "off", ...
                "ButtonPushedFcn", @(~, ~) app.openDefaultFocusView());
            app.FocusViewButton.Layout.Column = 2;

            app.OverlayOpacityLabel = uilabel(app.ViewControlGrid, ...
                "Text", "Overlay opacity", ...
                "HorizontalAlignment", "right", ...
                "FontColor", [0.35 0.39 0.45]);
            app.OverlayOpacityLabel.Layout.Column = 4;

            app.OverlayOpacitySlider = uislider(app.ViewControlGrid, ...
                "Limits", [0 1], ...
                "Value", 0.55, ...
                "MajorTicks", [0 0.5 1], ...
                "ValueChangingFcn", @(~, event) app.updateOverlayOpacity(event.Value), ...
                "ValueChangedFcn", @(src, ~) app.updateOverlayOpacity(src.Value));
            app.OverlayOpacitySlider.Layout.Column = 5;
        end

        function createInsightPanel(app)
            app.InsightGrid = uigridlayout(app.InsightPanel, [9 1]);
            app.InsightGrid.RowHeight = {32, 140, 24, 24, 38, 68, 38, 90, "1x"};
            app.InsightGrid.ColumnWidth = {"1x"};
            app.InsightGrid.Padding = [10 12 10 10];
            app.InsightGrid.RowSpacing = 7;

            app.InsightTitleLabel = uilabel(app.InsightGrid, ...
                "Text", "Evaluation", ...
                "FontSize", 18, ...
                "FontWeight", "bold", ...
                "FontColor", [0.12 0.15 0.20]);
            app.InsightTitleLabel.Layout.Row = 1;

            metricData = { ...
                'Precision', '--', '--'; ...
                'Recall', '--', '--'; ...
                'F1', '--', '--'; ...
                'IoU', '--', '--'; ...
                'Time (s/image)', '--', '--'};
            app.EvaluationMetricsTable = uitable(app.InsightGrid, ...
                "Data", metricData, ...
                "ColumnName", {'Metric', 'DL', 'Classical'}, ...
                "RowName", {}, ...
                "ColumnEditable", [false false false], ...
                "ColumnWidth", {108, 78, 80}, ...
                "BackgroundColor", [1 1 1; 0.965 0.975 0.985], ...
                "FontSize", 11);
            app.EvaluationMetricsTable.Layout.Row = 2;
            numericStyle = uistyle("HorizontalAlignment", "center");
            addStyle(app.EvaluationMetricsTable, numericStyle, ...
                "column", [2 3]);
            f1Style = uistyle( ...
                "FontWeight", "bold", ...
                "BackgroundColor", [0.92 0.96 1.00]);
            addStyle(app.EvaluationMetricsTable, f1Style, "row", 3);

            thresholdSection = app.makeSectionLabel(app.InsightGrid, "THRESHOLD", 3);
            thresholdSection.Tooltip = "Binary decision threshold applied to the cached probability map.";

            thresholdHeader = uigridlayout(app.InsightGrid, [1 2]);
            thresholdHeader.Layout.Row = 4;
            thresholdHeader.ColumnWidth = {"1x", 48};
            thresholdHeader.RowHeight = {"1x"};
            thresholdHeader.Padding = [0 0 0 0];
            uilabel(thresholdHeader, "Text", "Crack probability");
            app.ThresholdValueLabel = uilabel(thresholdHeader, ...
                "Text", "0.33", ...
                "HorizontalAlignment", "right", ...
                "FontWeight", "bold", ...
                "FontColor", [0.08 0.36 0.72]);
            app.ThresholdValueLabel.Layout.Column = 2;

            app.ThresholdSlider = uislider(app.InsightGrid, ...
                "Limits", [0 1], ...
                "Value", app.CurrentThreshold, ...
                "MajorTicks", [0 0.25 0.5 0.75 1], ...
                "ValueChangingFcn", @(~, event) app.updateThreshold(event.Value), ...
                "ValueChangedFcn", @(src, ~) app.updateThreshold(src.Value));
            app.ThresholdSlider.Layout.Row = 5;

            app.ConfigurationStatusLabel = uilabel(app.InsightGrid, ...
                "Text", sprintf(['Final Four-Model Ensemble\n' ...
                    'Frozen weights: 0.660 / 0.102 / 0.102 / 0.136']), ...
                "HorizontalAlignment", "center", ...
                "FontSize", 11, ...
                "WordWrap", "on", ...
                "FontColor", [0.15 0.52 0.31]);
            app.ConfigurationStatusLabel.Layout.Row = 6;

            configurationButtons = uigridlayout(app.InsightGrid, [1 1]);
            configurationButtons.Layout.Row = 7;
            configurationButtons.ColumnWidth = {"1x"};
            configurationButtons.RowHeight = {"1x"};
            configurationButtons.Padding = [0 0 0 0];

            app.ResetConfigurationButton = uibutton(configurationButtons, "push", ...
                "Text", "Reset Threshold", ...
                "ButtonPushedFcn", @(~, ~) app.resetConfiguration());
            app.ResetConfigurationButton.Layout.Column = 1;

            app.OverlayLegendPanel = uipanel(app.InsightGrid, ...
                "Title", "Overlay legend", ...
                "FontWeight", "bold", ...
                "BackgroundColor", [1 1 1]);
            app.OverlayLegendPanel.Layout.Row = 8;
            legendGrid = uigridlayout(app.OverlayLegendPanel, [3 2]);
            legendGrid.RowHeight = {"1x", "1x", "1x"};
            legendGrid.ColumnWidth = {24, "1x"};
            legendGrid.Padding = [8 4 8 5];
            legendGrid.RowSpacing = 3;
            legendGrid.ColumnSpacing = 7;
            app.addLegendRow(legendGrid, 1, [0.13 0.72 0.32], "True Positive");
            app.addLegendRow(legendGrid, 2, [0.91 0.22 0.18], "False Positive");
            app.addLegendRow(legendGrid, 3, [0.10 0.43 0.90], "False Negative");
        end

        function createAnnotationWorkspace(app)
            app.AnnotationGrid = uigridlayout(app.WorkspacePanel, [2 1]);
            app.AnnotationGrid.RowHeight = {"1x", 86};
            app.AnnotationGrid.ColumnWidth = {"1x"};
            app.AnnotationGrid.Padding = [12 12 12 8];
            app.AnnotationGrid.RowSpacing = 8;
            app.AnnotationGrid.Visible = "off";

            app.AnnotationAxes = uiaxes(app.AnnotationGrid);
            app.AnnotationAxes.Layout.Row = 1;
            app.AnnotationAxes.XTick = [];
            app.AnnotationAxes.YTick = [];
            app.AnnotationAxes.Box = "on";
            app.AnnotationAxes.Toolbar.Visible = "off";
            disableDefaultInteractivity(app.AnnotationAxes);
            app.AnnotationAxes.ButtonDownFcn = ...
                @app.handleAnnotationButtonDown;
            app.UIFigure.WindowButtonMotionFcn = ...
                @app.handleAnnotationMotion;
            app.UIFigure.WindowButtonUpFcn = ...
                @app.handleAnnotationButtonUp;
            app.UIFigure.WindowScrollWheelFcn = ...
                @app.handleAnnotationScroll;
            app.showAxesMessage(app.AnnotationAxes, ...
                "Manual Crack Annotation", "Load an image to begin");

            app.AnnotationControlGrid = uigridlayout(app.AnnotationGrid, [2 8]);
            app.AnnotationControlGrid.Layout.Row = 2;
            app.AnnotationControlGrid.ColumnWidth = ...
                {100, 80, 80, "1x", 65, 65, 85, 95};
            app.AnnotationControlGrid.RowHeight = {36, 36};
            app.AnnotationControlGrid.Padding = [0 0 0 0];
            app.AnnotationControlGrid.ColumnSpacing = 6;

            app.DrawCrackButton = uibutton(app.AnnotationControlGrid, "push", ...
                "Text", "Draw Crack", ...
                "BackgroundColor", [0.08 0.36 0.72], ...
                "FontColor", [1 1 1], ...
                "ButtonPushedFcn", @(~, ~) app.selectAnnotationTool("draw"));
            app.DrawCrackButton.Layout.Column = 1;

            app.EraseCrackButton = uibutton(app.AnnotationControlGrid, "push", ...
                "Text", "Erase", ...
                "ButtonPushedFcn", @(~, ~) app.selectAnnotationTool("erase"));
            app.EraseCrackButton.Layout.Column = 2;

            brushLabel = uilabel(app.AnnotationControlGrid, ...
                "Text", "Brush", "HorizontalAlignment", "right");
            brushLabel.Layout.Column = 3;

            app.AnnotationBrushSlider = uislider(app.AnnotationControlGrid, ...
                "Limits", [1 31], ...
                "Value", app.AnnotationBrushWidth, ...
                "MajorTicks", [1 7 15 23 31], ...
                "ValueChangingFcn", @(~, event) ...
                    app.updateAnnotationBrush(event.Value), ...
                "ValueChangedFcn", @(src, ~) ...
                    app.updateAnnotationBrush(src.Value));
            app.AnnotationBrushSlider.Layout.Column = 4;

            app.AnnotationBrushValueLabel = uilabel(app.AnnotationControlGrid, ...
                "Text", "7 px", "HorizontalAlignment", "center");
            app.AnnotationBrushValueLabel.Layout.Column = 5;

            app.UndoAnnotationButton = uibutton(app.AnnotationControlGrid, "push", ...
                "Text", "Undo", ...
                "ButtonPushedFcn", @(~, ~) app.undoAnnotation());
            app.UndoAnnotationButton.Layout.Column = 6;

            app.ClearAnnotationButton = uibutton(app.AnnotationControlGrid, "push", ...
                "Text", "Clear Mask", ...
                "ButtonPushedFcn", @(~, ~) app.clearAnnotation());
            app.ClearAnnotationButton.Layout.Column = 7;

            saveCompareGrid = uigridlayout(app.AnnotationControlGrid, [1 2]);
            saveCompareGrid.Layout.Column = 8;
            saveCompareGrid.ColumnWidth = {"1x", "1x"};
            saveCompareGrid.Padding = [0 0 0 0];
            saveCompareGrid.ColumnSpacing = 4;
            app.SaveAnnotationButton = uibutton(saveCompareGrid, "push", ...
                "Text", "Save", ...
                "ButtonPushedFcn", @(~, ~) app.saveAnnotationMask());
            app.SaveAnnotationButton.Layout.Column = 1;
            app.CompareAnnotationButton = uibutton(saveCompareGrid, "push", ...
                "Text", "Compare", ...
                "ButtonPushedFcn", @(~, ~) app.compareAnnotation());
            app.CompareAnnotationButton.Layout.Column = 2;

            zoomGrid = uigridlayout(app.AnnotationControlGrid, [1 6]);
            zoomGrid.Layout.Row = 2;
            zoomGrid.Layout.Column = [1 8];
            zoomGrid.ColumnWidth = {48, 60, 70, 60, 90, "1x"};
            zoomGrid.RowHeight = {"1x"};
            zoomGrid.Padding = [0 0 0 0];
            zoomGrid.ColumnSpacing = 6;
            zoomLabel = uilabel(zoomGrid, ...
                "Text", "Zoom", "FontWeight", "bold");
            zoomLabel.Layout.Column = 1;
            app.AnnotationZoomOutButton = uibutton(zoomGrid, "push", ...
                "Text", "Zoom -", ...
                "ButtonPushedFcn", @(~, ~) app.stepAnnotationZoom(-1));
            app.AnnotationZoomOutButton.Layout.Column = 2;
            app.AnnotationZoomValueLabel = uilabel(zoomGrid, ...
                "Text", "1.0x", "HorizontalAlignment", "center", ...
                "FontWeight", "bold");
            app.AnnotationZoomValueLabel.Layout.Column = 3;
            app.AnnotationZoomInButton = uibutton(zoomGrid, "push", ...
                "Text", "Zoom +", ...
                "ButtonPushedFcn", @(~, ~) app.stepAnnotationZoom(1));
            app.AnnotationZoomInButton.Layout.Column = 4;
            app.AnnotationZoomResetButton = uibutton(zoomGrid, "push", ...
                "Text", "Reset View", ...
                "ButtonPushedFcn", @(~, ~) app.resetAnnotationZoom());
            app.AnnotationZoomResetButton.Layout.Column = 5;
            inkLabel = uilabel(zoomGrid, ...
                "Text", "Ink: translucent magenta", ...
                "FontColor", [0.82 0.08 0.42]);
            inkLabel.Layout.Column = 6;

            app.AnnotationInsightGrid = uigridlayout(app.InsightPanel, [7 1]);
            app.AnnotationInsightGrid.RowHeight = {42, 34, 34, 24, 145, 70, "1x"};
            app.AnnotationInsightGrid.ColumnWidth = {"1x"};
            app.AnnotationInsightGrid.Padding = [10 12 10 10];
            app.AnnotationInsightGrid.RowSpacing = 8;
            app.AnnotationInsightGrid.Visible = "off";

            annotationTitle = uilabel(app.AnnotationInsightGrid, ...
                "Text", "Manual Reference", ...
                "FontSize", 18, "FontWeight", "bold");
            annotationTitle.Layout.Row = 1;
            app.AnnotationCoverageLabel = uilabel(app.AnnotationInsightGrid, ...
                "Text", "Crack coverage: 0.00%", ...
                "FontWeight", "bold");
            app.AnnotationCoverageLabel.Layout.Row = 2;
            app.AnnotationStrokeLabel = uilabel(app.AnnotationInsightGrid, ...
                "Text", "Strokes: 0");
            app.AnnotationStrokeLabel.Layout.Row = 3;
            metricTitle = app.makeSectionLabel( ...
                app.AnnotationInsightGrid, "DL VS MANUAL", 4);
            metricTitle.Tooltip = "The manual mask is treated as the reference.";
            app.AnnotationMetricsTable = uitable(app.AnnotationInsightGrid, ...
                "Data", {'Precision', '--'; 'Recall', '--'; ...
                    'F1', '--'; 'IoU', '--'}, ...
                "ColumnName", {'Metric', 'DL'}, ...
                "RowName", {}, ...
                "ColumnEditable", [false false], ...
                "ColumnWidth", {130, 130}, ...
                "BackgroundColor", [1 1 1; 0.965 0.975 0.985]);
            app.AnnotationMetricsTable.Layout.Row = 5;
            annotationHint = uilabel(app.AnnotationInsightGrid, ...
                "Text", ["Choose Draw Crack or Erase. Hold the left mouse " ...
                    "button and drag directly over the image."], ...
                "WordWrap", "on", ...
                "FontColor", [0.42 0.45 0.50]);
            annotationHint.Layout.Row = 6;
        end

        function createStatisticsWorkspace(app)
            app.StatisticsGrid = uigridlayout(app.WorkspacePanel, [3 1]);
            app.StatisticsGrid.RowHeight = {108, "0.9x", "1.15x"};
            app.StatisticsGrid.ColumnWidth = {"1x"};
            app.StatisticsGrid.Padding = [12 12 12 12];
            app.StatisticsGrid.RowSpacing = 10;
            app.StatisticsGrid.Visible = "off";

            app.StatisticsCardsGrid = uigridlayout(app.StatisticsGrid, [1 5]);
            app.StatisticsCardsGrid.Layout.Row = 1;
            app.StatisticsCardsGrid.ColumnWidth = {"1x", "1x", "1x", ...
                "1x", "1x"};
            app.StatisticsCardsGrid.Padding = [0 0 0 0];
            app.StatisticsCardsGrid.ColumnSpacing = 8;
            app.StatisticsAnalysedValueLabel = app.createStatisticsCard( ...
                app.StatisticsCardsGrid, 1, "ANALYSED");
            app.StatisticsGTValueLabel = app.createStatisticsCard( ...
                app.StatisticsCardsGrid, 2, "GT AVAILABLE");
            app.StatisticsDLF1ValueLabel = app.createStatisticsCard( ...
                app.StatisticsCardsGrid, 3, "DL MEAN F1");
            app.StatisticsClassicalF1ValueLabel = app.createStatisticsCard( ...
                app.StatisticsCardsGrid, 4, "CLASSICAL MEAN F1");
            app.StatisticsDLTimeValueLabel = app.createStatisticsCard( ...
                app.StatisticsCardsGrid, 5, "DL TIME / IMAGE");

            app.StatisticsComparisonAxes = uiaxes(app.StatisticsGrid);
            app.StatisticsComparisonAxes.Layout.Row = 2;
            app.showAxesMessage(app.StatisticsComparisonAxes, ...
                "DL vs Classical", "Analyse images with Ground Truth");

            app.StatisticsCaseTable = uitable(app.StatisticsGrid, ...
                "Data", cell(0, 5), ...
                "ColumnName", {'Image', 'DL F1', 'Classical F1', ...
                    'Delta F1', 'Finding'}, ...
                "RowName", {}, ...
                "ColumnEditable", false(1, 5), ...
                "ColumnWidth", {340, 110, 145, 125, 250}, ...
                "FontSize", 11, ...
                "BackgroundColor", [1 1 1; 0.965 0.975 0.985], ...
                "CellSelectionCallback", ...
                    @(~, event) app.openStatisticsCase(event));
            app.StatisticsCaseTable.Layout.Row = 3;

            app.StatisticsInsightGrid = uigridlayout(app.InsightPanel, [5 1]);
            app.StatisticsInsightGrid.RowHeight = {44, 38, 170, 40, "1x"};
            app.StatisticsInsightGrid.ColumnWidth = {"1x"};
            app.StatisticsInsightGrid.Padding = [10 12 10 10];
            app.StatisticsInsightGrid.RowSpacing = 6;
            app.StatisticsInsightGrid.Visible = "off";

            statisticsTitle = uilabel(app.StatisticsInsightGrid, ...
                "Text", "Folder Summary", ...
                "FontSize", 18, "FontWeight", "bold");
            statisticsTitle.Layout.Row = 1;
            app.StatisticsBatchLabel = uilabel(app.StatisticsInsightGrid, ...
                "Text", "Analysed: 0 / 0", "FontWeight", "bold");
            app.StatisticsBatchLabel.Layout.Row = 2;
            summaryData = { ...
                'Total analysis time', '--'; ...
                'DL time / image', '--'; ...
                'Classical time / image', '--'; ...
                'DL Zero-F1', '--'; ...
                'DL crack coverage', '--'; ...
                'Classical coverage', '--'};
            app.StatisticsMetricsTable = uitable( ...
                app.StatisticsInsightGrid, ...
                "Data", summaryData, ...
                "ColumnName", {'Summary', 'Value'}, ...
                "RowName", {}, ...
                "ColumnEditable", [false false], ...
                "ColumnWidth", {165, 100}, ...
                "BackgroundColor", [1 1 1; 0.955 0.972 0.992], ...
                "FontSize", 11);
            app.StatisticsMetricsTable.Layout.Row = 3;
            summaryNumericStyle = uistyle( ...
                "HorizontalAlignment", "center");
            addStyle(app.StatisticsMetricsTable, summaryNumericStyle, ...
                "column", 2);
            metricNameStyle = uistyle("FontWeight", "bold");
            addStyle(app.StatisticsMetricsTable, metricNameStyle, ...
                "column", 1);
            scoreStyle = uistyle( ...
                "FontWeight", "bold", ...
                "BackgroundColor", [0.91 0.95 1.00]);
            addStyle(app.StatisticsMetricsTable, scoreStyle, "row", [1 2]);
            app.StatisticsRefreshButton = uibutton( ...
                app.StatisticsInsightGrid, "push", ...
                "Text", "Refresh Statistics", ...
                "ButtonPushedFcn", @(~, ~) app.refreshStatistics());
            app.StatisticsRefreshButton.Layout.Row = 4;
            findingGuideGrid = uigridlayout(app.StatisticsInsightGrid, [9 1]);
            findingGuideGrid.Layout.Row = 5;
            findingGuideGrid.RowHeight = {32, 26, 26, 26, 26, 26, 26, ...
                12, "1x"};
            findingGuideGrid.ColumnWidth = {"1x"};
            findingGuideGrid.Padding = [0 8 0 0];
            findingGuideGrid.RowSpacing = 2;
            findingTitle = uilabel(findingGuideGrid, ...
                "Text", "Finding Guide", ...
                "FontSize", 14, ...
                "FontWeight", "bold", ...
                "FontColor", [0.10 0.18 0.28]);
            findingTitle.Layout.Row = 1;
            findingTexts = [ ...
                "Missed  -  DL F1 = 0"; ...
                "Low F1  -  DL F1 < 0.40"; ...
                "DL worse  -  Delta F1 < -0.05"; ...
                "DL better  -  Delta F1 > +0.15"; ...
                "Normal  -  no marked issue"; ...
                "No GT  -  accuracy unavailable"];
            findingColours = [ ...
                0.76 0.16 0.16; ...
                0.88 0.43 0.08; ...
                0.76 0.16 0.16; ...
                0.10 0.55 0.30; ...
                0.30 0.36 0.44; ...
                0.42 0.45 0.50];
            for findingIndex = 1:numel(findingTexts)
                findingLabel = uilabel(findingGuideGrid, ...
                    "Text", findingTexts(findingIndex), ...
                    "FontSize", 11, ...
                    "FontWeight", "bold", ...
                    "FontColor", findingColours(findingIndex, :));
                findingLabel.Layout.Row = findingIndex + 1;
            end
            statisticsHint = uilabel(findingGuideGrid, ...
                "Text", ["Select any case row to open it in Analysis. " ...
                "Cached results are reused; inference is not repeated."], ...
                "WordWrap", "on", ...
                "VerticalAlignment", "top", ...
                "FontColor", [0.42 0.45 0.50]);
            statisticsHint.Layout.Row = 9;
        end

        function valueLabel = createStatisticsCard(~, parent, column, titleText)
            card = uipanel(parent, ...
                "BackgroundColor", [0.965 0.975 0.992], ...
                "BorderColor", [0.80 0.85 0.92]);
            card.Layout.Column = column;
            cardGrid = uigridlayout(card, [2 1]);
            cardGrid.RowHeight = {30, "1x"};
            cardGrid.Padding = [10 8 10 8];
            titleLabel = uilabel(cardGrid, ...
                "Text", titleText, ...
                "FontSize", 10, ...
                "FontWeight", "bold", ...
                "FontColor", [0.35 0.42 0.52], ...
                "HorizontalAlignment", "center");
            titleLabel.Layout.Row = 1;
            valueLabel = uilabel(cardGrid, ...
                "Text", "--", ...
                "FontSize", 22, ...
                "FontWeight", "bold", ...
                "FontColor", [0.06 0.34 0.72], ...
                "HorizontalAlignment", "center");
            valueLabel.Layout.Row = 2;
        end

        function resizeStatisticsCaseColumns(app)
            if isempty(app.StatisticsCaseTable) || ...
                    ~isvalid(app.StatisticsCaseTable)
                return;
            end
            availableWidth = app.StatisticsCaseTable.Position(3) - 22;
            if availableWidth < 600
                return;
            end
            columnRatios = [0.34 0.11 0.15 0.13 0.27];
            columnWidths = floor(availableWidth .* columnRatios);
            app.StatisticsCaseTable.ColumnWidth = num2cell(columnWidths);
        end

        function addLegendRow(~, parent, row, colour, textValue)
            swatch = uilabel(parent, ...
                "Text", "", ...
                "BackgroundColor", colour);
            swatch.Layout.Row = row;
            swatch.Layout.Column = 1;
            legendLabel = uilabel(parent, "Text", textValue, "FontSize", 11);
            legendLabel.Layout.Row = row;
            legendLabel.Layout.Column = 2;
        end

        function updateThreshold(app, newValue)
            app.CurrentThreshold = newValue;
            app.ThresholdValueLabel.Text = sprintf("%.2f", newValue);
            app.markConfigurationCustom();
            if app.hasProbabilityMaps()
                app.refreshAIResult();
            elseif ~isempty(app.AIProbabilityMap)
                app.AIPredictionMask = ...
                    app.AIProbabilityMap >= app.CurrentThreshold;
                app.displayAIResult();
                app.updateAIMetrics();
            end
        end

        function markConfigurationCustom(app)
            app.ModelStatusLabel.Text = sprintf( ...
                'Final Ensemble | Threshold %.2f | %s', ...
                app.CurrentThreshold, app.formatInferenceMode());
        end

        function resetConfiguration(app)
            app.CurrentThreshold = 0.33;
            app.ThresholdSlider.Value = app.CurrentThreshold;
            app.ThresholdValueLabel.Text = "0.33";
            app.ModelStatusLabel.Text = "Final Ensemble | Not loaded";
            if app.hasProbabilityMaps()
                app.refreshAIResult();
                app.ModelStatusLabel.Text = "Final Ensemble | Loaded | " + ...
                    app.formatInferenceMode();
            elseif ~isempty(app.AIProbabilityMap)
                app.AIPredictionMask = ...
                    app.AIProbabilityMap >= app.CurrentThreshold;
                app.displayAIResult();
                app.updateAIMetrics();
                app.ModelStatusLabel.Text = "Final Ensemble | Cached";
            end
        end

        function requestModelReload(app)
            clear predictCrackEnsemble
            clear predictCrackEnsembleAdaptive
            app.PerModelProbabilityMaps = struct();
            app.AIProbabilityMap = [];
            app.AIPredictionMask = [];
            app.AIElapsedSeconds = NaN;
            app.AIInferenceMode = "";
            app.AITileGrid = [1 1];
            app.ModelStatusLabel.Text = "Final Ensemble | Reloaded from disk on next run";
            app.ExportButton.Enable = "off";
        end

        function exportCurrentResult(app)
            if isempty(app.OriginalImage) || isempty(app.AIPredictionMask)
                uialert(app.UIFigure, ...
                    "Run analysis before exporting results.", ...
                    "No analysis result");
                return;
            end
            if strlength(app.CurrentImagePath) > 0
                [defaultFolder, sourceName] = fileparts(app.CurrentImagePath);
            else
                defaultFolder = app.getRawDataFolder();
                sourceName = "crack_result";
            end
            selectedFolder = uigetdir(defaultFolder, ...
                'Select a folder for the CrackVision export');
            if isequal(selectedFolder, 0)
                return;
            end
            timestamp = string(datetime('now', ...
                'Format', 'yyyyMMdd_HHmmss'));
            exportFolder = fullfile(string(selectedFolder), ...
                string(sourceName) + "_CrackVision_" + timestamp);
            mkdir(exportFolder);

            imwrite(app.OriginalImage, ...
                fullfile(exportFolder, '01_original.png'));
            if app.GroundTruthLoaded
                imwrite(uint8(app.GroundTruthMask) .* 255, ...
                    fullfile(exportFolder, '02_ground_truth.png'));
            end
            imwrite(uint8(app.AIPredictionMask) .* 255, ...
                fullfile(exportFolder, '03_dl_prediction.png'));
            imwrite(app.makeAIOverlay(), ...
                fullfile(exportFolder, '04_dl_overlay.png'));
            if ~isempty(app.ClassicalPredictionMask)
                imwrite(uint8(app.ClassicalPredictionMask) .* 255, ...
                    fullfile(exportFolder, '05_classical_prediction.png'));
                imwrite(app.makeMaskOverlay(app.ClassicalPredictionMask), ...
                    fullfile(exportFolder, '06_classical_overlay.png'));
            end
            if ~isempty(app.ManualReferenceMask) && ...
                    nnz(app.ManualReferenceMask) > 0
                imwrite(uint8(app.ManualReferenceMask) .* 255, ...
                    fullfile(exportFolder, '07_manual_reference.png'));
            end

            metricData = app.EvaluationMetricsTable.Data;
            metrics = cell2table(metricData, ...
                'VariableNames', {'Metric', 'DL', 'Classical'});
            writetable(metrics, fullfile(exportFolder, 'metrics.csv'));
            configuration = table(app.CurrentThreshold, ...
                app.OverlayOpacity, ...
                "Final four-model DL ensemble", ...
                'VariableNames', ...
                {'Threshold', 'OverlayOpacity', 'Model'});
            writetable(configuration, ...
                fullfile(exportFolder, 'configuration.csv'));
            app.ModelStatusLabel.Text = "Export complete | " + exportFolder;
            uialert(app.UIFigure, ...
                "Export completed:" + newline + exportFolder, ...
                "CrackVision export");
        end

        function runAIAnalysis(app)
            if isempty(app.OriginalImage)
                uialert(app.UIFigure, "Load an image before analysis.", "No image");
                return;
            end
            if numel(app.ImageFiles) > 1
                app.runFolderAnalysis();
                return;
            end

            app.AnalyseImageButton.Enable = "off";
            app.AnalyseImageButton.Text = "Analysing...";
            app.ModelStatusLabel.Text = "Loading final ensemble and running inference";
            app.updateAnalysisProgress(0, "Single image");
            drawnow;

            try
                app.performCurrentAIInference(0, 0.95, "DL ensemble");
                app.performCurrentClassicalAnalysis();
                app.updateAnalysisProgress(1, "Analysis complete");
                if app.CurrentImageIndex >= 1 && ...
                        app.CurrentImageIndex <= numel(app.AnalysisCompleted)
                    app.AnalysisCompleted(app.CurrentImageIndex) = true;
                    app.CachedClassicalPredictionMasks{app.CurrentImageIndex} = ...
                        app.ClassicalPredictionMask;
                    app.CachedClassicalElapsedSeconds(app.CurrentImageIndex) = ...
                        app.ClassicalElapsedSeconds;
                end
                app.ModelStatusLabel.Text = "Final Ensemble | Loaded | " + ...
                    app.formatInferenceMode();
                app.DeviceStatusLabel.Text = "Device: Auto";
                app.ExportButton.Enable = "on";
            catch errorInfo
                app.ModelStatusLabel.Text = "Analysis failed";
                uialert(app.UIFigure, errorInfo.message, "DL analysis error");
            end

            app.AnalyseImageButton.Text = "Analyse Image";
            if app.BatchAnalysisRunning
                app.AnalyseImageButton.Enable = "off";
            else
                app.AnalyseImageButton.Enable = "on";
            end
        end

        function performCurrentAIInference(app, progressBase, progressScale, contextText)
            appFolder = fileparts(mfilename('fullpath'));
            uiFolder = fileparts(appFolder);
            deliveryFolder = fullfile(uiFolder, ...
                'ELEC9773_Final_UNet_Ensemble_UI_v1');
            addpath(deliveryFolder);

            progressCallback = @(fraction) app.updateAnalysisProgress( ...
                progressBase + progressScale .* fraction, contextText);
            [~, ~, inferenceInfo] = predictCrackEnsembleAdaptive( ...
                app.OriginalImage, "auto", progressCallback);
            if ~isfield(inferenceInfo, 'PerModelProbabilities')
                error('CrackVision:MissingPerModelProbabilities', ...
                    'The delivery function did not return component probability maps.');
            end

            app.PerModelProbabilityMaps = inferenceInfo.PerModelProbabilities;
            app.AIElapsedSeconds = inferenceInfo.ElapsedSeconds;
            app.AIInferenceMode = string(inferenceInfo.InferenceMode);
            app.AITileGrid = double(inferenceInfo.TileGrid);
            if app.CurrentImageIndex >= 1 && ...
                    app.CurrentImageIndex <= numel(app.CachedAIInferenceModes)
                app.CachedAIInferenceModes(app.CurrentImageIndex) = ...
                    app.AIInferenceMode;
                app.CachedAITileGrids(app.CurrentImageIndex, :) = ...
                    app.AITileGrid;
            end
            app.refreshAIResult();
        end

        function label = formatInferenceMode(app)
            if strcmpi(app.AIInferenceMode, "tiled")
                label = sprintf('Tiled %d x %d', ...
                    app.AITileGrid(1), app.AITileGrid(2));
            elseif strcmpi(app.AIInferenceMode, "whole")
                label = "Whole";
            else
                label = "Not analysed";
            end
        end

        function packed = quantizeProbability(~, probability)
            probability = min(max(double(probability), 0), 1);
            packed = uint8(round(255 .* probability));
        end

        function runFolderAnalysis(app)
            imageCount = numel(app.ImageFiles);
            if imageCount < 2
                uialert(app.UIFigure, ...
                    "Open a folder with multiple images before batch analysis.", ...
                    "No image folder");
                return;
            end
            if app.BatchAnalysisRunning
                return;
            end

            firstPending = find(~app.AnalysisCompleted, 1);
            if isempty(firstPending)
                app.updateAnalysisProgress(1, "Folder complete");
                app.ModelStatusLabel.Text = "Folder analysis complete";
                app.AnalyseImageButton.Text = "Analyse Folder";
                return;
            end

            app.BatchAnalysisRunning = true;
            app.BatchPauseRequested = false;
            app.AnalyseImageButton.Enable = "off";
            app.AnalyseImageButton.Text = "Analysing Folder...";
            app.PauseAnalysisButton.Enable = "on";
            app.PauseAnalysisButton.Text = "Pause";
            app.OpenImageButton.Enable = "off";
            app.OpenFolderButton.Enable = "off";
            app.LoadGroundTruthButton.Enable = "off";
            app.ClearAllButton.Enable = "off";
            app.updateFolderNavigation();

            try
                for imageIndex = firstPending:imageCount
                    if app.BatchPauseRequested
                        break;
                    end
                    if app.AnalysisCompleted(imageIndex)
                        continue;
                    end

                    app.CurrentImageIndex = imageIndex;
                    app.loadCurrentImage();
                    completedBefore = nnz(app.AnalysisCompleted);
                    contextText = sprintf('Folder %d / %d', imageIndex, imageCount);
                    app.ModelStatusLabel.Text = "Batch analysis | " + contextText;
                    drawnow;

                    app.performCurrentAIInference( ...
                        completedBefore / imageCount, ...
                        0.95 / imageCount, contextText + " | DL");
                    app.ModelStatusLabel.Text = "Batch analysis | " + ...
                        contextText + " | " + app.formatInferenceMode();
                    app.performCurrentClassicalAnalysis();
                    app.AnalysisCompleted(imageIndex) = true;
                    app.CachedAIElapsedSeconds(imageIndex) = ...
                        app.AIElapsedSeconds;
                    app.CachedClassicalPredictionMasks{imageIndex} = ...
                        app.ClassicalPredictionMask;
                    app.CachedClassicalElapsedSeconds(imageIndex) = ...
                        app.ClassicalElapsedSeconds;
                    app.updateAnalysisProgress( ...
                        nnz(app.AnalysisCompleted) / imageCount, contextText);
                    drawnow;
                end
            catch errorInfo
                app.BatchPauseRequested = true;
                uialert(app.UIFigure, errorInfo.message, ...
                    "Folder analysis error");
            end

            app.BatchAnalysisRunning = false;
            app.AnalyseImageButton.Enable = "on";
            app.OpenImageButton.Enable = "on";
            app.OpenFolderButton.Enable = "on";
            app.LoadGroundTruthButton.Enable = "on";
            app.ClearAllButton.Enable = "on";
            if app.BatchPauseRequested
                app.AnalyseImageButton.Text = "Resume Folder";
                app.PauseAnalysisButton.Text = "Paused";
                app.PauseAnalysisButton.Enable = "off";
                app.ModelStatusLabel.Text = sprintf( ...
                    'Folder paused | %d / %d complete', ...
                    nnz(app.AnalysisCompleted), imageCount);
            else
                app.AnalyseImageButton.Text = "Analyse Folder";
                app.PauseAnalysisButton.Text = "Pause";
                app.PauseAnalysisButton.Enable = "off";
                app.ModelStatusLabel.Text = sprintf( ...
                    'Folder complete | %d / %d', imageCount, imageCount);
            end
            app.updateFolderNavigation();
        end

        function toggleFolderPause(app)
            if app.BatchAnalysisRunning
                app.BatchPauseRequested = true;
                app.PauseAnalysisButton.Text = "Pausing...";
                app.PauseAnalysisButton.Enable = "off";
                app.ModelStatusLabel.Text = ...
                    "Pause requested | finishing current forward pass";
                drawnow;
            end
        end

        function updateAnalysisProgress(app, fraction, contextText)
            fraction = min(max(double(fraction), 0), 1);
            percentage = 100 .* fraction;
            drawnow limitrate;
            trackPosition = app.AnalysisProgressTrack.Position;
            if fraction <= 0 || trackPosition(3) <= 1
                app.AnalysisProgressFill.Visible = "off";
            else
                app.AnalysisProgressFill.Visible = "on";
                app.AnalysisProgressFill.Position = [0 0, ...
                    max(1, trackPosition(3) .* fraction), ...
                    max(1, trackPosition(4))];
            end
            if nargin < 3 || strlength(string(contextText)) == 0
                app.AnalysisProgressLabel.Text = sprintf('%.0f%%', percentage);
            else
                app.AnalysisProgressLabel.Text = sprintf( ...
                    '%.0f%% | %s', percentage, contextText);
            end
            drawnow limitrate;
        end

        function refreshAIResult(app)
            maps = app.PerModelProbabilityMaps;
            app.AIProbabilityMap = ...
                app.CurrentModelWeights(1) .* maps.ResNet + ...
                app.CurrentModelWeights(2) .* maps.HardRS + ...
                app.CurrentModelWeights(3) .* maps.Photometric + ...
                app.CurrentModelWeights(4) .* maps.Transfer;
            app.AIPredictionMask = app.AIProbabilityMap >= app.CurrentThreshold;
            if app.CurrentImageIndex >= 1 && ...
                    app.CurrentImageIndex <= numel(app.CachedAIElapsedSeconds)
                app.CachedAIProbabilityMaps{app.CurrentImageIndex} = ...
                    app.quantizeProbability(app.AIProbabilityMap);
                app.CachedAIElapsedSeconds(app.CurrentImageIndex) = ...
                    app.AIElapsedSeconds;
            end
            app.displayAIResult();
            app.updateAIMetrics();
        end

        function displayAIResult(app)
            cla(app.AIPredictionAxes);
            imageHandle = imshow(app.AIPredictionMask, "Parent", app.AIPredictionAxes);
            imageHandle.HitTest = "off";
            title(app.AIPredictionAxes, ...
                sprintf("DL Prediction | t = %.2f", app.CurrentThreshold), ...
                "FontWeight", "bold");

            overlayImage = app.makeAIOverlay();
            cla(app.AIOverlayAxes);
            imageHandle = imshow(overlayImage, "Parent", app.AIOverlayAxes);
            imageHandle.HitTest = "off";
            title(app.AIOverlayAxes, "DL Overlay", "FontWeight", "bold");
            app.refreshFocusView();
        end

        function overlayImage = makeAIOverlay(app)
            overlayImage = app.makeMaskOverlay(app.AIPredictionMask);
        end

        function overlayImage = makeMaskOverlay(app, predictionMask)
            baseImage = app.ensureDisplayRgb(app.OriginalImage);
            overlayImage = baseImage;
            alpha = app.OverlayOpacity;

            if app.GroundTruthLoaded
                referenceMask = app.matchMaskSize(app.GroundTruthMask);
                truePositive = predictionMask & referenceMask;
                falsePositive = predictionMask & ~referenceMask;
                falseNegative = ~predictionMask & referenceMask;
                colouredPixels = truePositive | falsePositive | falseNegative;
                colourImage = zeros(size(baseImage));
                colourImage(:, :, 1) = falsePositive;
                colourImage(:, :, 2) = truePositive;
                colourImage(:, :, 3) = falseNegative;
            else
                colouredPixels = predictionMask;
                colourImage = zeros(size(baseImage));
                colourImage(:, :, 1) = predictionMask;
                colourImage(:, :, 2) = 0.35 .* predictionMask;
            end

            for channel = 1:3
                baseChannel = overlayImage(:, :, channel);
                colourChannel = colourImage(:, :, channel);
                baseChannel(colouredPixels) = ...
                    (1 - alpha) .* baseChannel(colouredPixels) + ...
                    alpha .* colourChannel(colouredPixels);
                overlayImage(:, :, channel) = baseChannel;
            end
        end

        function updateAIMetrics(app)
            tableData = app.EvaluationMetricsTable.Data;
            if app.GroundTruthLoaded
                referenceMask = app.matchMaskSize(app.GroundTruthMask);
                predictionMask = app.AIPredictionMask;
                truePositive = nnz(predictionMask & referenceMask);
                falsePositive = nnz(predictionMask & ~referenceMask);
                falseNegative = nnz(~predictionMask & referenceMask);
                precision = app.safeRatio(truePositive, truePositive + falsePositive);
                recall = app.safeRatio(truePositive, truePositive + falseNegative);
                f1 = app.safeRatio(2 * precision * recall, precision + recall);
                iou = app.safeRatio(truePositive, ...
                    truePositive + falsePositive + falseNegative);
                tableData{1, 2} = sprintf('%.4f', precision);
                tableData{2, 2} = sprintf('%.4f', recall);
                tableData{3, 2} = sprintf('%.4f', f1);
                tableData{4, 2} = sprintf('%.4f', iou);
            else
                tableData(1:4, 2) = {'--'; '--'; '--'; '--'};
            end
            tableData{5, 2} = sprintf('%.2f', app.AIElapsedSeconds);
            app.EvaluationMetricsTable.Data = tableData;
        end

        function performCurrentClassicalAnalysis(app)
            appFolder = fileparts(mfilename('fullpath'));
            uiFolder = fileparts(appFolder);
            matlabCodeFolder = fileparts(uiFolder);
            addpath(matlabCodeFolder);

            startTime = tic;
            app.ClassicalPredictionMask = classicalCrackBaseline( ...
                app.OriginalImage);
            app.ClassicalElapsedSeconds = toc(startTime);
            app.displayClassicalResult();
            app.updateClassicalMetrics();
        end

        function displayClassicalResult(app)
            cla(app.ClassicalPredictionAxes);
            imageHandle = imshow(app.ClassicalPredictionMask, ...
                "Parent", app.ClassicalPredictionAxes);
            imageHandle.HitTest = "off";
            title(app.ClassicalPredictionAxes, ...
                "Classical | Sauvola", "FontWeight", "bold");

            overlayImage = app.makeMaskOverlay(app.ClassicalPredictionMask);
            cla(app.ClassicalOverlayAxes);
            imageHandle = imshow(overlayImage, "Parent", app.ClassicalOverlayAxes);
            imageHandle.HitTest = "off";
            title(app.ClassicalOverlayAxes, ...
                "Classical Overlay", "FontWeight", "bold");
            app.refreshFocusView();
        end

        function updateClassicalMetrics(app)
            tableData = app.EvaluationMetricsTable.Data;
            if app.GroundTruthLoaded
                referenceMask = app.matchMaskSize(app.GroundTruthMask);
                predictionMask = app.ClassicalPredictionMask;
                truePositive = nnz(predictionMask & referenceMask);
                falsePositive = nnz(predictionMask & ~referenceMask);
                falseNegative = nnz(~predictionMask & referenceMask);
                precision = app.safeRatio(truePositive, truePositive + falsePositive);
                recall = app.safeRatio(truePositive, truePositive + falseNegative);
                f1 = app.safeRatio(2 * precision * recall, precision + recall);
                iou = app.safeRatio(truePositive, ...
                    truePositive + falsePositive + falseNegative);
                tableData{1, 3} = sprintf('%.4f', precision);
                tableData{2, 3} = sprintf('%.4f', recall);
                tableData{3, 3} = sprintf('%.4f', f1);
                tableData{4, 3} = sprintf('%.4f', iou);
            else
                tableData(1:4, 3) = {'--'; '--'; '--'; '--'};
            end
            tableData{5, 3} = sprintf('%.3f', app.ClassicalElapsedSeconds);
            app.EvaluationMetricsTable.Data = tableData;
        end

        function updateOverlayOpacity(app, newValue)
            app.OverlayOpacity = newValue;
            if ~isempty(app.AIPredictionMask)
                app.displayAIResult();
            end
            if ~isempty(app.ClassicalPredictionMask)
                app.displayClassicalResult();
            end
        end

        function tf = hasProbabilityMaps(app)
            requiredFields = {'ResNet', 'HardRS', 'Photometric', 'Transfer'};
            tf = isstruct(app.PerModelProbabilityMaps) && ...
                all(isfield(app.PerModelProbabilityMaps, requiredFields));
        end

        function mask = matchMaskSize(app, mask)
            targetSize = size(app.OriginalImage, [1 2]);
            if ~isequal(size(mask, [1 2]), targetSize)
                mask = imresize(mask, targetSize, 'nearest');
            end
            mask = logical(mask);
        end

        function image = ensureDisplayRgb(~, image)
            if ndims(image) == 2 || size(image, 3) == 1
                image = repmat(image(:, :, 1), [1 1 3]);
            else
                image = image(:, :, 1:3);
            end
            image = im2double(image);
        end

        function value = safeRatio(~, numerator, denominator)
            if denominator == 0
                value = 0;
            else
                value = numerator / denominator;
            end
        end

        function openDefaultFocusView(app)
            if ~isempty(app.AIPredictionMask)
                app.openFocusView("DL Overlay");
            elseif ~isempty(app.OriginalImage)
                app.openFocusView("Original");
            end
        end

        function openFocusView(app, viewName)
            viewName = string(viewName);
            switch viewName
                case "Original"
                    displayValue = app.OriginalImage;
                case "Ground Truth"
                    if ~app.GroundTruthLoaded
                        return;
                    end
                    displayValue = app.GroundTruthMask;
                case "DL Prediction"
                    displayValue = app.AIPredictionMask;
                case "DL Overlay"
                    if isempty(app.AIPredictionMask)
                        return;
                    end
                    displayValue = app.makeAIOverlay();
                case "Classical Prediction"
                    displayValue = app.ClassicalPredictionMask;
                case "Classical Overlay"
                    if isempty(app.ClassicalPredictionMask)
                        return;
                    end
                    displayValue = app.makeMaskOverlay(app.ClassicalPredictionMask);
                otherwise
                    return;
            end
            if isempty(displayValue)
                return;
            end

            app.FocusedViewName = viewName;
            app.EvaluationGrid.Visible = "off";
            app.FocusAxes.Visible = "on";
            cla(app.FocusAxes);
            imshow(displayValue, "Parent", app.FocusAxes);
            title(app.FocusAxes, viewName, ...
                "FontSize", 15, "FontWeight", "bold");
            app.SixPanelViewButton.BackgroundColor = [0.94 0.94 0.95];
            app.FocusViewButton.BackgroundColor = [0.88 0.93 0.99];
            app.FocusViewButton.FontWeight = "bold";
        end

        function showSixPanelView(app)
            app.FocusedViewName = "";
            app.FocusAxes.Visible = "off";
            app.EvaluationGrid.Visible = "on";
            app.SixPanelViewButton.BackgroundColor = [0.88 0.93 0.99];
            app.SixPanelViewButton.FontWeight = "bold";
            app.FocusViewButton.BackgroundColor = [0.94 0.94 0.95];
            app.FocusViewButton.FontWeight = "normal";
        end

        function refreshFocusView(app)
            if strlength(app.FocusedViewName) > 0
                app.openFocusView(app.FocusedViewName);
                drawnow limitrate;
            end
        end

        function label = makeSectionLabel(~, parent, textValue, row)
            label = uilabel(parent, ...
                "Text", textValue, ...
                "FontSize", 11, ...
                "FontWeight", "bold", ...
                "FontColor", [0.08 0.36 0.72]);
            label.Layout.Row = row;
        end

        function ax = makeResultAxes(app, parent, titleText, row, column)
            ax = uiaxes(parent);
            ax.Layout.Row = row;
            ax.Layout.Column = column;
            ax.XTick = [];
            ax.YTick = [];
            ax.Box = "on";
            ax.Color = [0.975 0.98 0.985];
            title(ax, titleText, "FontSize", 12, "FontWeight", "bold");
            ax.Toolbar.Visible = "off";
            ax.ButtonDownFcn = @(~, ~) app.openFocusView(titleText);
            messageHandle = text(ax, 0.5, 0.5, "Waiting for input", ...
                "Units", "normalized", ...
                "HorizontalAlignment", "center", ...
                "Color", [0.55 0.57 0.60]);
            messageHandle.HitTest = "off";
        end

        function openImage(app)
            defaultFolder = app.getRawDataFolder();
            [fileNames, folderName] = uigetfile( ...
                {"*.jpg;*.jpeg;*.png;*.bmp;*.tif;*.tiff", "Image files"}, ...
                "Select one or more road images", ...
                fullfile(defaultFolder, '*.*'), ...
                "MultiSelect", "on");
            if isequal(fileNames, 0)
                return;
            end

            % 单选返回字符，多选返回元胞数组；统一为纵向路径列表。
            if ischar(fileNames) || ...
                    (isstring(fileNames) && isscalar(fileNames))
                selectedNames = string(fileNames);
            else
                selectedNames = string(fileNames(:));
            end
            selectedPaths = fullfile(string(folderName), selectedNames);

            imageFiles = strings(0, 1);
            groundTruthFiles = strings(0, 1);
            for selectedIndex = 1:numel(selectedPaths)
                [imagePath, pairedMaskPath, proceed] = ...
                    app.guardSingleImageSelection(selectedPaths(selectedIndex));
                if ~proceed
                    return;
                end

                % 若原图和同名PNG mask同时被选中，只保留一个原图条目。
                existingIndex = find(strcmpi(imageFiles, imagePath), 1);
                if isempty(existingIndex)
                    imageFiles(end + 1, 1) = imagePath; %#ok<AGROW>
                    groundTruthFiles(end + 1, 1) = pairedMaskPath; %#ok<AGROW>
                elseif strlength(pairedMaskPath) > 0
                    groundTruthFiles(existingIndex) = pairedMaskPath;
                end
            end

            % 复用文件夹配对规则，为所选子集补充同目录或兄弟目录GT。
            [folderImages, folderMasks] = ...
                app.resolveFolderPairs(string(folderName));
            for imageIndex = 1:numel(imageFiles)
                if strlength(groundTruthFiles(imageIndex)) > 0
                    continue;
                end
                folderIndex = find(strcmpi(folderImages, imageFiles(imageIndex)), 1);
                if ~isempty(folderIndex) && ...
                        strlength(folderMasks(folderIndex)) > 0
                    groundTruthFiles(imageIndex) = folderMasks(folderIndex);
                end
            end

            app.ImageFiles = imageFiles;
            app.GroundTruthFiles = groundTruthFiles;
            app.resetFolderAnalysisState(numel(imageFiles));
            app.CurrentImageIndex = 1;
            app.CurrentFolderPath = string(folderName);
            pairedCount = nnz(strlength(groundTruthFiles) > 0);
            if numel(imageFiles) > 1 && pairedCount > 0
                app.PairingMode = "Multi-select + paired GT";
            elseif numel(imageFiles) > 1
                app.PairingMode = "Multi-select";
            elseif pairedCount > 0
                app.PairingMode = "Single image + paired GT";
            else
                app.PairingMode = "Single image";
            end
            app.loadCurrentImage();
        end

        function clearAllImages(app)
            if app.BatchAnalysisRunning
                return;
            end

            app.OriginalImage = [];
            app.GroundTruthMask = [];
            app.GroundTruthLoaded = false;
            app.PerModelProbabilityMaps = struct();
            app.AIProbabilityMap = [];
            app.AIPredictionMask = [];
            app.AIElapsedSeconds = NaN;
            app.AIInferenceMode = "";
            app.AITileGrid = [1 1];
            app.ClassicalPredictionMask = [];
            app.ClassicalElapsedSeconds = NaN;
            app.ManualReferenceMask = [];
            app.AnnotationHistory = cell(0, 1);
            app.AnnotationStrokeCount = 0;
            app.AnnotationDrawing = false;
            app.AnnotationLastPoint = [];
            app.AnnotationImageHandle = [];
            app.AnnotationZoomIndex = 1;
            app.CurrentImagePath = "";
            app.ImageFiles = strings(0, 1);
            app.GroundTruthFiles = strings(0, 1);
            app.CurrentImageIndex = 0;
            app.CurrentFolderPath = "";
            app.PairingMode = "Images only";
            app.FocusedViewName = "";
            app.resetFolderAnalysisState(0);

            app.showAxesMessage(app.OriginalAxes, "Original", "Waiting for input");
            app.showAxesMessage(app.GroundTruthAxes, "Ground Truth", "Optional");
            app.showAxesMessage(app.AIPredictionAxes, "DL Prediction", "Run analysis");
            app.showAxesMessage(app.AIOverlayAxes, "DL Overlay", "Run analysis");
            app.showAxesMessage(app.ClassicalPredictionAxes, ...
                "Classical Prediction", "Run analysis");
            app.showAxesMessage(app.ClassicalOverlayAxes, ...
                "Classical Overlay", "Run analysis");
            app.showAxesMessage(app.AnnotationAxes, ...
                "Manual Crack Annotation", "Load an image to begin");

            tableData = app.EvaluationMetricsTable.Data;
            tableData(:, 2:3) = {'--', '--'; '--', '--'; '--', '--'; ...
                '--', '--'; '--', '--'};
            app.EvaluationMetricsTable.Data = tableData;
            app.AnnotationMetricsTable.Data(:, 2) = ...
                {'--'; '--'; '--'; '--'};
            app.updateAnnotationSummary();
            app.AnalyseImageButton.Enable = "off";
            app.FocusViewButton.Enable = "off";
            app.ExportButton.Enable = "off";
            app.ModelStatusLabel.Text = "Final Ensemble | No image";
            app.updateFolderNavigation();
            app.showSixPanelView();
        end

        function openImageFolder(app)
            selectedFolder = uigetdir(app.getRawDataFolder(), ...
                'Select a folder containing road images');
            if isequal(selectedFolder, 0)
                return;
            end

            [selectedFolder, proceed] = ...
                app.guardImageFolderSelection(string(selectedFolder));
            if ~proceed
                return;
            end

            [imageFiles, groundTruthFiles, pairingMode] = ...
                app.resolveFolderPairs(string(selectedFolder));

            if isempty(imageFiles)
                uialert(app.UIFigure, ...
                    "No supported image files were found in this folder.", ...
                    "Empty image folder");
                return;
            end

            if pairingMode == "Images only" && ...
                    app.isLikelyMaskFolder(imageFiles)
                choice = uiconfirm(app.UIFigure, ...
                    "Most files in the selected folder look like binary masks." + ...
                    " Select the road-image folder instead.", ...
                    "Possible mask folder", ...
                    "Options", ["Choose Another", "Use Anyway"], ...
                    "DefaultOption", 1, "CancelOption", 1);
                if ~strcmp(choice, 'Use Anyway')
                    return;
                end
            end

            app.ImageFiles = imageFiles;
            app.GroundTruthFiles = groundTruthFiles;
            app.resetFolderAnalysisState(numel(imageFiles));
            app.CurrentImageIndex = 1;
            app.CurrentFolderPath = string(selectedFolder);
            app.PairingMode = pairingMode;
            app.loadCurrentImage();
        end

        function showPreviousImage(app)
            if app.CurrentImageIndex > 1
                app.CurrentImageIndex = app.CurrentImageIndex - 1;
                app.loadCurrentImage();
            end
        end

        function showNextImage(app)
            if app.CurrentImageIndex < numel(app.ImageFiles)
                app.CurrentImageIndex = app.CurrentImageIndex + 1;
                app.loadCurrentImage();
            end
        end

        function jumpToImage(app, requestedIndex)
            if isempty(app.ImageFiles) || app.BatchAnalysisRunning
                return;
            end
            requestedIndex = round(requestedIndex);
            requestedIndex = min(max(requestedIndex, 1), numel(app.ImageFiles));
            app.CurrentImageIndex = requestedIndex;
            app.loadCurrentImage();
        end

        function loadCurrentImage(app)
            if app.CurrentImageIndex < 1 || ...
                    app.CurrentImageIndex > numel(app.ImageFiles)
                return;
            end
            app.CurrentImagePath = app.ImageFiles(app.CurrentImageIndex);
            app.OriginalImage = imread(app.CurrentImagePath);
            app.GroundTruthMask = [];
            app.GroundTruthLoaded = false;
            app.PerModelProbabilityMaps = struct();
            app.AIProbabilityMap = [];
            app.AIPredictionMask = [];
            app.AIElapsedSeconds = NaN;
            app.AIInferenceMode = "";
            app.AITileGrid = [1 1];
            app.ClassicalPredictionMask = [];
            app.ClassicalElapsedSeconds = NaN;
            app.AnnotationHistory = cell(0, 1);
            app.AnnotationStrokeCount = 0;
            app.AnnotationDrawing = false;
            app.AnnotationLastPoint = [];
            app.AnnotationImageHandle = [];
            app.AnnotationZoomIndex = 1;
            if app.CurrentImageIndex <= numel(app.CachedManualReferenceMasks) && ...
                    ~isempty(app.CachedManualReferenceMasks{app.CurrentImageIndex})
                app.ManualReferenceMask = ...
                    app.CachedManualReferenceMasks{app.CurrentImageIndex};
                app.AnnotationStrokeCount = ...
                    app.CachedAnnotationStrokeCounts(app.CurrentImageIndex);
            else
                app.ManualReferenceMask = false( ...
                    size(app.OriginalImage, 1), size(app.OriginalImage, 2));
            end
            app.clearAnnotationMetrics();
            cla(app.OriginalAxes);
            imageHandle = imshow(app.OriginalImage, "Parent", app.OriginalAxes);
            imageHandle.HitTest = "off";
            title(app.OriginalAxes, "Original", "FontWeight", "bold");
            if numel(app.GroundTruthFiles) >= app.CurrentImageIndex && ...
                    strlength(app.GroundTruthFiles(app.CurrentImageIndex)) > 0
                app.applyGroundTruthFile(app.GroundTruthFiles(app.CurrentImageIndex));
            else
                app.showAxesMessage(app.GroundTruthAxes, "Ground Truth", "Optional");
            end
            app.showAxesMessage(app.AIPredictionAxes, "DL Prediction", "Run analysis");
            app.showAxesMessage(app.AIOverlayAxes, "DL Overlay", "Run analysis");
            app.showAxesMessage(app.ClassicalPredictionAxes, ...
                "Classical Prediction", "Run analysis");
            app.showAxesMessage(app.ClassicalOverlayAxes, ...
                "Classical Overlay", "Run analysis");
            tableData = app.EvaluationMetricsTable.Data;
            tableData(:, 2:3) = {'--', '--'; '--', '--'; '--', '--'; ...
                '--', '--'; '--', '--'};
            app.EvaluationMetricsTable.Data = tableData;
            if app.CurrentImageIndex <= numel(app.AnalysisCompleted) && ...
                    app.AnalysisCompleted(app.CurrentImageIndex) && ...
                    ~isempty(app.CachedAIProbabilityMaps{app.CurrentImageIndex})
                app.AIProbabilityMap = double( ...
                    app.CachedAIProbabilityMaps{app.CurrentImageIndex}) ./ 255;
                app.AIPredictionMask = ...
                    app.AIProbabilityMap >= app.CurrentThreshold;
                app.AIElapsedSeconds = ...
                    app.CachedAIElapsedSeconds(app.CurrentImageIndex);
                if app.CurrentImageIndex <= ...
                        numel(app.CachedAIInferenceModes)
                    app.AIInferenceMode = ...
                        app.CachedAIInferenceModes(app.CurrentImageIndex);
                    app.AITileGrid = ...
                        app.CachedAITileGrids(app.CurrentImageIndex, :);
                end
                app.displayAIResult();
                app.updateAIMetrics();
                if app.CurrentImageIndex <= ...
                        numel(app.CachedClassicalPredictionMasks) && ...
                        ~isempty(app.CachedClassicalPredictionMasks{app.CurrentImageIndex})
                    app.ClassicalPredictionMask = ...
                        app.CachedClassicalPredictionMasks{app.CurrentImageIndex};
                    app.ClassicalElapsedSeconds = ...
                        app.CachedClassicalElapsedSeconds(app.CurrentImageIndex);
                    app.displayClassicalResult();
                    app.updateClassicalMetrics();
                end
                app.ExportButton.Enable = "on";
            end
            if app.BatchAnalysisRunning
                app.AnalyseImageButton.Enable = "off";
            else
                app.AnalyseImageButton.Enable = "on";
            end
            app.FocusViewButton.Enable = "on";
            if isempty(app.AIPredictionMask)
                app.ExportButton.Enable = "off";
            end
            [~, displayName, extension] = fileparts(app.CurrentImagePath);
            matchedCount = sum(strlength(app.GroundTruthFiles) > 0);
            inferenceSuffix = "";
            if app.CurrentImageIndex <= numel(app.AnalysisCompleted) && ...
                    app.AnalysisCompleted(app.CurrentImageIndex)
                inferenceSuffix = " | " + app.formatInferenceMode();
            end
            if numel(app.ImageFiles) > 1
                app.ModelStatusLabel.Text = sprintf( ...
                    'Ready | %s%s | GT %d/%d | %s%s', ...
                    displayName, extension, matchedCount, ...
                    numel(app.ImageFiles), app.PairingMode, inferenceSuffix);
            else
                app.ModelStatusLabel.Text = "Ready | " + displayName + ...
                    extension + inferenceSuffix;
            end
            app.updateFolderNavigation();
            app.showSixPanelView();
            app.refreshAnnotationView();
        end

        function updateFolderNavigation(app)
            imageCount = numel(app.ImageFiles);
            if imageCount == 0
                app.ImagePositionField.Value = 1;
                app.ImagePositionField.Enable = "off";
                app.ImageCountLabel.Text = "/ 0";
                app.PreviousImageButton.Enable = "off";
                app.NextImageButton.Enable = "off";
                app.ImageListBox.Enable = "off";
                return;
            end
            app.ImagePositionField.Limits = [1 imageCount];
            app.ImagePositionField.Value = app.CurrentImageIndex;
            app.ImageCountLabel.Text = sprintf('/ %d', imageCount);
            app.ImageListBox.Value = app.CurrentImageIndex;
            if app.BatchAnalysisRunning
                app.ImagePositionField.Enable = "off";
                app.PreviousImageButton.Enable = "off";
                app.NextImageButton.Enable = "off";
                app.ImageListBox.Enable = "off";
                return;
            end
            app.ImagePositionField.Enable = "on";
            app.ImageListBox.Enable = "on";
            if app.CurrentImageIndex > 1
                app.PreviousImageButton.Enable = "on";
            else
                app.PreviousImageButton.Enable = "off";
            end
            if app.CurrentImageIndex < imageCount
                app.NextImageButton.Enable = "on";
            else
                app.NextImageButton.Enable = "off";
            end
        end

        function resetFolderAnalysisState(app, imageCount)
            app.CachedAIProbabilityMaps = cell(imageCount, 1);
            app.CachedAIElapsedSeconds = nan(imageCount, 1);
            app.CachedAIInferenceModes = strings(imageCount, 1);
            app.CachedAITileGrids = ones(imageCount, 2);
            app.CachedClassicalPredictionMasks = cell(imageCount, 1);
            app.CachedClassicalElapsedSeconds = nan(imageCount, 1);
            app.CachedManualReferenceMasks = cell(imageCount, 1);
            app.CachedAnnotationStrokeCounts = zeros(imageCount, 1);
            app.AnalysisCompleted = false(imageCount, 1);
            app.BatchAnalysisRunning = false;
            app.BatchPauseRequested = false;
            app.AnalysisProgressFill.Visible = "off";
            app.AnalysisProgressLabel.Text = "0%";
            app.PauseAnalysisButton.Enable = "off";
            app.PauseAnalysisButton.Text = "Pause";
            if imageCount == 0
                app.AnalyseImageButton.Enable = "off";
                app.AnalyseImageButton.Text = "Analyse Image";
            elseif imageCount > 1
                app.AnalyseImageButton.Enable = "on";
                app.AnalyseImageButton.Text = "Analyse Folder";
            else
                app.AnalyseImageButton.Enable = "on";
                app.AnalyseImageButton.Text = "Analyse Image";
            end
            app.refreshImageList();
        end

        function refreshImageList(app)
            imageCount = numel(app.ImageFiles);
            if imageCount == 0
                app.ImageListBox.Items = {'No images loaded'};
                app.ImageListBox.ItemsData = 0;
                app.ImageListBox.Value = 0;
                app.ImageListBox.Enable = "off";
                return;
            end
            names = strings(imageCount, 1);
            for imageIndex = 1:imageCount
                [~, name, extension] = fileparts(app.ImageFiles(imageIndex));
                names(imageIndex) = name + extension;
            end
            app.ImageListBox.Items = cellstr(names);
            app.ImageListBox.ItemsData = 1:imageCount;
            app.ImageListBox.Value = min(max(app.CurrentImageIndex, 1), ...
                imageCount);
            app.ImageListBox.Enable = "on";
        end

        function openGroundTruth(app)
            defaultFolder = app.getRawDataFolder();
            [fileName, folderName] = uigetfile( ...
                {"*.png;*.bmp;*.tif;*.tiff;*.jpg;*.jpeg", "Mask files"}, ...
                "Select a ground-truth mask", ...
                fullfile(defaultFolder, '*.*'));
            if isequal(fileName, 0)
                return;
            end
            maskPath = string(fullfile(folderName, fileName));
            if numel(app.GroundTruthFiles) ~= numel(app.ImageFiles)
                app.GroundTruthFiles = strings(size(app.ImageFiles));
            end
            if app.CurrentImageIndex >= 1
                app.GroundTruthFiles(app.CurrentImageIndex) = maskPath;
            end
            app.applyGroundTruthFile(maskPath);
        end

        function [imagePath, pairedMaskPath, proceed] = ...
                guardSingleImageSelection(app, selectedPath)
            imagePath = selectedPath;
            pairedMaskPath = "";
            proceed = true;

            [folderPath, stem, extension] = fileparts(selectedPath);
            sourceExtensions = [".jpg", ".jpeg", ".bmp", ".tif", ".tiff"];
            sourceCandidates = strings(0, 1);
            if strcmpi(extension, '.png')
                for extensionIndex = 1:numel(sourceExtensions)
                    candidatePath = fullfile(folderPath, stem + ...
                        sourceExtensions(extensionIndex));
                    if isfile(candidatePath)
                        sourceCandidates(end + 1, 1) = candidatePath; %#ok<AGROW>
                    end
                end
            end

            if numel(sourceCandidates) == 1
                choice = uiconfirm(app.UIFigure, ...
                    "This PNG has a same-name road image and is likely its " + ...
                    "Ground Truth mask.", ...
                    "Possible Ground Truth selected", ...
                    "Options", ["Open Original + GT", "Use Anyway", "Cancel"], ...
                    "DefaultOption", 1, "CancelOption", 3);
                if strcmp(choice, 'Open Original + GT')
                    imagePath = sourceCandidates(1);
                    pairedMaskPath = selectedPath;
                elseif strcmp(choice, 'Cancel')
                    proceed = false;
                end
                return;
            end

            if app.isLikelyMaskFile(selectedPath)
                choice = uiconfirm(app.UIFigure, ...
                    "The selected file looks like a binary Ground Truth mask, " + ...
                    "not a road image.", ...
                    "Possible mask selected", ...
                    "Options", ["Choose Another", "Use Anyway"], ...
                    "DefaultOption", 1, "CancelOption", 1);
                proceed = strcmp(choice, 'Use Anyway');
            end
        end

        function [selectedFolder, proceed] = ...
                guardImageFolderSelection(app, selectedFolder)
            proceed = true;
            [parentFolder, selectedName] = fileparts(selectedFolder);
            maskFolderNames = ["test_lab", "train_lab", "masks", "mask", "lab"];
            imageFolderNames = ["test_img", "train_img", "images", "image", "img"];
            mappingIndex = find(strcmpi(selectedName, maskFolderNames), 1);
            if isempty(mappingIndex)
                return;
            end

            siblingFolder = app.findSiblingFolder( ...
                string(parentFolder), imageFolderNames(mappingIndex));
            if strlength(siblingFolder) == 0
                return;
            end

            choice = uiconfirm(app.UIFigure, ...
                "You selected a Ground Truth folder. A paired road-image " + ...
                "folder was found beside it.", ...
                "Ground Truth folder selected", ...
                "Options", ["Open Image Folder", "Use Anyway", "Cancel"], ...
                "DefaultOption", 1, "CancelOption", 3);
            if strcmp(choice, 'Open Image Folder')
                selectedFolder = siblingFolder;
            elseif strcmp(choice, 'Cancel')
                proceed = false;
            end
        end

        function likely = isLikelyMaskFolder(app, files)
            sampleCount = min(numel(files), 8);
            if sampleCount == 0
                likely = false;
                return;
            end
            sampleIndices = unique(round(linspace(1, numel(files), sampleCount)));
            maskLikeCount = 0;
            for sampleIndex = sampleIndices
                maskLikeCount = maskLikeCount + ...
                    app.isLikelyMaskFile(files(sampleIndex));
            end
            likely = maskLikeCount >= ceil(0.75 * numel(sampleIndices));
        end

        function likely = isLikelyMaskFile(~, filePath)
            likely = false;
            try
                rawImage = imread(filePath);
                if ndims(rawImage) == 3
                    if size(rawImage, 3) < 3
                        rawImage = rawImage(:, :, 1);
                    else
                        channelDifference = max(abs(double(rawImage(:, :, 1)) - ...
                            double(rawImage(:, :, 2))), [], 'all');
                        channelDifference = max(channelDifference, ...
                            max(abs(double(rawImage(:, :, 1)) - ...
                            double(rawImage(:, :, 3))), [], 'all'));
                        if channelDifference > 0
                            return;
                        end
                        rawImage = rawImage(:, :, 1);
                    end
                end
                sample = im2double(rawImage);
                sample = sample(1:max(1, floor(numel(sample) / 250000)):end);
                nearBinaryFraction = mean(sample <= (1 / 255) | ...
                    sample >= (254 / 255));
                quantisedValues = unique(round(sample .* 255));
                likely = nearBinaryFraction >= 0.995 && ...
                    numel(quantisedValues) <= 4;
            catch
                likely = false;
            end
        end

        function applyGroundTruthFile(app, maskPath)
            rawMask = imread(maskPath);
            if ndims(rawMask) == 3
                rawMask = rgb2gray(rawMask);
            end
            app.GroundTruthMask = rawMask > 0;
            app.GroundTruthLoaded = true;
            cla(app.GroundTruthAxes);
            imageHandle = imshow(app.GroundTruthMask, "Parent", app.GroundTruthAxes);
            imageHandle.HitTest = "off";
            title(app.GroundTruthAxes, "Ground Truth", "FontWeight", "bold");
            if ~isempty(app.AIPredictionMask)
                app.displayAIResult();
                app.updateAIMetrics();
            end
            if ~isempty(app.ClassicalPredictionMask)
                app.displayClassicalResult();
                app.updateClassicalMetrics();
            end
        end

        function [imageFiles, groundTruthFiles, pairingMode] = ...
                resolveFolderPairs(app, selectedFolder)
            allFiles = app.listSupportedImageFiles(selectedFolder);
            imageFiles = strings(0, 1);
            groundTruthFiles = strings(0, 1);
            pairingMode = "Images only";
            if isempty(allFiles)
                return;
            end

            fileCount = numel(allFiles);
            stems = strings(fileCount, 1);
            extensions = strings(fileCount, 1);
            for fileIndex = 1:fileCount
                [~, stems(fileIndex), extensions(fileIndex)] = ...
                    fileparts(allFiles(fileIndex));
            end
            lowerStems = lower(stems);
            isPng = strcmpi(extensions, '.png');

            % CRACK500 convention: image.jpg and image.png share one folder.
            nonPngIndices = find(~isPng);
            sameFolderMasks = strings(numel(nonPngIndices), 1);
            for index = 1:numel(nonPngIndices)
                imageIndex = nonPngIndices(index);
                candidates = find(isPng & lowerStems == lowerStems(imageIndex));
                if numel(candidates) == 1
                    sameFolderMasks(index) = allFiles(candidates);
                end
            end
            if any(strlength(sameFolderMasks) > 0)
                imageFiles = allFiles(nonPngIndices);
                groundTruthFiles = sameFolderMasks;
                pairingMode = "Same-folder pairing";
                return;
            end

            % DeepCrack and common dataset conventions: sibling image/mask folders.
            [parentFolder, selectedName] = fileparts(selectedFolder);
            sourceNames = ["test_img", "train_img", "images", "image", "img"];
            targetNames = ["test_lab", "train_lab", "masks", "mask", "lab"];
            mappingIndex = find(strcmpi(selectedName, sourceNames), 1);
            if ~isempty(mappingIndex)
                siblingFolder = app.findSiblingFolder( ...
                    string(parentFolder), targetNames(mappingIndex));
                if strlength(siblingFolder) > 0
                    siblingFiles = app.listSupportedImageFiles(siblingFolder);
                    groundTruthFiles = strings(size(allFiles));
                    siblingStems = strings(numel(siblingFiles), 1);
                    for siblingIndex = 1:numel(siblingFiles)
                        [~, siblingStems(siblingIndex)] = ...
                            fileparts(siblingFiles(siblingIndex));
                    end
                    for imageIndex = 1:numel(allFiles)
                        candidates = find(strcmpi(stems(imageIndex), siblingStems));
                        if numel(candidates) == 1
                            groundTruthFiles(imageIndex) = siblingFiles(candidates);
                        end
                    end
                    imageFiles = allFiles;
                    pairingMode = "Sibling-folder pairing";
                    return;
                end
            end

            imageFiles = allFiles;
            groundTruthFiles = strings(size(allFiles));
        end

        function files = listSupportedImageFiles(~, folderPath)
            extensions = {'*.jpg', '*.jpeg', '*.png', '*.bmp', '*.tif', '*.tiff'};
            files = strings(0, 1);
            for extensionIndex = 1:numel(extensions)
                entries = dir(fullfile(folderPath, extensions{extensionIndex}));
                if ~isempty(entries)
                    folders = string({entries.folder})';
                    names = string({entries.name})';
                    files = [files; fullfile(folders, names)]; %#ok<AGROW>
                end
            end
            files = unique(files);
            [~, order] = sort(lower(files));
            files = files(order);
        end

        function siblingFolder = findSiblingFolder(~, parentFolder, targetName)
            siblingFolder = "";
            entries = dir(parentFolder);
            entries = entries([entries.isdir]);
            names = string({entries.name});
            matchIndex = find(strcmpi(names, targetName), 1);
            if ~isempty(matchIndex)
                siblingFolder = string(fullfile(parentFolder, names(matchIndex)));
            end
        end

        function showAxesMessage(~, ax, titleText, messageText)
            cla(ax);
            ax.XTick = [];
            ax.YTick = [];
            title(ax, titleText, "FontWeight", "bold");
            messageHandle = text(ax, 0.5, 0.5, messageText, ...
                "Units", "normalized", ...
                "HorizontalAlignment", "center", ...
                "Color", [0.55 0.57 0.60]);
            messageHandle.HitTest = "off";
        end

        function rawDataFolder = getRawDataFolder(~)
            appFolder = fileparts(mfilename('fullpath'));
            uiFolder = fileparts(appFolder);
            matlabFolder = fileparts(uiFolder);
            codeFolder = fileparts(matlabFolder);
            projectFolder = fileparts(codeFolder);
            rawDataFolder = fullfile(projectFolder, 'data', 'raw');
            if ~isfolder(rawDataFolder)
                rawDataFolder = pwd;
            end
        end

        function updateAnnotationBrush(app, value)
            app.AnnotationBrushWidth = max(1, round(value));
            app.AnnotationBrushValueLabel.Text = sprintf( ...
                '%d px', app.AnnotationBrushWidth);
        end

        function stepAnnotationZoom(app, direction)
            if isempty(app.OriginalImage)
                return;
            end
            nextIndex = app.AnnotationZoomIndex + sign(direction);
            app.AnnotationZoomIndex = min(max(nextIndex, 1), ...
                numel(app.AnnotationZoomLevels));
            app.applyAnnotationZoom([]);
        end

        function scrollAnnotationZoom(app, event)
            if app.CurrentMode ~= "Annotate" || isempty(app.OriginalImage)
                return;
            end
            point = app.AnnotationAxes.CurrentPoint(1, 1:2);
            if ~app.annotationPointInsideImage(point)
                return;
            end
            direction = -sign(event.VerticalScrollCount);
            if direction == 0
                return;
            end
            nextIndex = app.AnnotationZoomIndex + direction;
            app.AnnotationZoomIndex = min(max(nextIndex, 1), ...
                numel(app.AnnotationZoomLevels));
            app.applyAnnotationZoom(point);
        end

        function resetAnnotationZoom(app)
            app.AnnotationZoomIndex = 1;
            app.applyAnnotationZoom([]);
        end

        function applyAnnotationZoom(app, requestedCentre)
            if isempty(app.OriginalImage) || isempty(app.AnnotationAxes)
                return;
            end
            imageSize = size(app.OriginalImage, [1 2]);
            zoomFactor = app.AnnotationZoomLevels(app.AnnotationZoomIndex);
            currentX = app.AnnotationAxes.XLim;
            currentY = app.AnnotationAxes.YLim;
            if ~isempty(requestedCentre) && ...
                    app.annotationPointInsideImage(requestedCentre)
                centreX = requestedCentre(1);
                centreY = requestedCentre(2);
            elseif any(~isfinite([currentX currentY]))
                centreX = (imageSize(2) + 1) / 2;
                centreY = (imageSize(1) + 1) / 2;
            else
                centreX = mean(currentX);
                centreY = mean(currentY);
            end
            viewWidth = imageSize(2) / zoomFactor;
            viewHeight = imageSize(1) / zoomFactor;
            xMinimum = min(max(centreX - viewWidth / 2, 0.5), ...
                imageSize(2) + 0.5 - viewWidth);
            yMinimum = min(max(centreY - viewHeight / 2, 0.5), ...
                imageSize(1) + 0.5 - viewHeight);
            app.AnnotationAxes.XLim = [xMinimum xMinimum + viewWidth];
            app.AnnotationAxes.YLim = [yMinimum yMinimum + viewHeight];
            app.AnnotationZoomValueLabel.Text = sprintf('%.1fx', zoomFactor);
            if app.AnnotationZoomIndex > 1
                app.AnnotationZoomOutButton.Enable = "on";
            else
                app.AnnotationZoomOutButton.Enable = "off";
            end
            if app.AnnotationZoomIndex < numel(app.AnnotationZoomLevels)
                app.AnnotationZoomInButton.Enable = "on";
            else
                app.AnnotationZoomInButton.Enable = "off";
            end
        end

        function selectAnnotationTool(app, toolName)
            app.AnnotationTool = string(toolName);
            if app.AnnotationTool == "erase"
                app.DrawCrackButton.BackgroundColor = [0.94 0.95 0.97];
                app.DrawCrackButton.FontColor = [0.10 0.18 0.29];
                app.EraseCrackButton.BackgroundColor = [0.91 0.22 0.18];
                app.EraseCrackButton.FontColor = [1 1 1];
                app.ModelStatusLabel.Text = "Annotation tool | Erase";
            else
                app.DrawCrackButton.BackgroundColor = [0.08 0.36 0.72];
                app.DrawCrackButton.FontColor = [1 1 1];
                app.EraseCrackButton.BackgroundColor = [0.94 0.95 0.97];
                app.EraseCrackButton.FontColor = [0.10 0.18 0.29];
                app.ModelStatusLabel.Text = "Annotation tool | Draw Crack";
            end
        end

        function handleAnnotationButtonDown(app, ~, ~)
            app.beginAnnotationPaint();
        end

        function handleAnnotationMotion(app, ~, ~)
            app.continueAnnotationPaint();
        end

        function handleAnnotationButtonUp(app, ~, ~)
            app.endAnnotationPaint();
        end

        function handleAnnotationScroll(app, ~, event)
            app.scrollAnnotationZoom(event);
        end

        function beginAnnotationPaint(app)
            if app.CurrentMode ~= "Annotate" || isempty(app.OriginalImage)
                return;
            end
            if ~strcmp(app.UIFigure.SelectionType, 'normal')
                return;
            end
            point = app.AnnotationAxes.CurrentPoint(1, 1:2);
            if ~app.annotationPointInsideImage(point)
                return;
            end
            if isempty(app.ManualReferenceMask)
                app.ManualReferenceMask = false( ...
                    size(app.OriginalImage, 1), size(app.OriginalImage, 2));
            end
            previousState = struct( ...
                'Mask', app.ManualReferenceMask, ...
                'StrokeCount', app.AnnotationStrokeCount);
            app.AnnotationHistory{end + 1, 1} = previousState;
            app.AnnotationDrawing = true;
            app.AnnotationLastPoint = point;
            app.applyAnnotationBrushSegment(point, point);
            app.refreshAnnotationView();
        end

        function continueAnnotationPaint(app)
            if ~app.AnnotationDrawing || isempty(app.OriginalImage)
                return;
            end
            point = app.AnnotationAxes.CurrentPoint(1, 1:2);
            imageSize = size(app.OriginalImage, [1 2]);
            point(1) = min(max(point(1), 1), imageSize(2));
            point(2) = min(max(point(2), 1), imageSize(1));
            app.applyAnnotationBrushSegment(app.AnnotationLastPoint, point);
            app.AnnotationLastPoint = point;
            app.refreshAnnotationView();
            drawnow limitrate nocallbacks
        end

        function endAnnotationPaint(app)
            if ~app.AnnotationDrawing
                return;
            end
            app.AnnotationDrawing = false;
            app.AnnotationLastPoint = [];
            app.AnnotationStrokeCount = app.AnnotationStrokeCount + 1;
            app.storeCurrentAnnotation();
            app.clearAnnotationMetrics();
            app.refreshAnnotationView();
        end

        function inside = annotationPointInsideImage(app, point)
            imageSize = size(app.OriginalImage, [1 2]);
            inside = all(isfinite(point)) && ...
                point(1) >= 1 && point(1) <= imageSize(2) && ...
                point(2) >= 1 && point(2) <= imageSize(1);
        end

        function applyAnnotationBrushSegment(app, firstPoint, secondPoint)
            imageSize = size(app.OriginalImage, [1 2]);
            sampleCount = max(1, ceil(max(abs(secondPoint - firstPoint))) + 1);
            x = round(linspace(firstPoint(1), secondPoint(1), sampleCount));
            y = round(linspace(firstPoint(2), secondPoint(2), sampleCount));
            valid = x >= 1 & x <= imageSize(2) & ...
                y >= 1 & y <= imageSize(1);
            centreMask = false(imageSize);
            centreMask(sub2ind(imageSize, y(valid), x(valid))) = true;
            radius = max(0, floor((app.AnnotationBrushWidth - 1) / 2));
            if radius > 0
                centreMask = imdilate(centreMask, strel('disk', radius, 0));
            end
            if app.AnnotationTool == "erase"
                app.ManualReferenceMask(centreMask) = false;
            else
                app.ManualReferenceMask(centreMask) = true;
            end
        end

        function undoAnnotation(app)
            app.AnnotationDrawing = false;
            app.AnnotationLastPoint = [];
            if isempty(app.AnnotationHistory)
                return;
            end
            previousState = app.AnnotationHistory{end};
            app.AnnotationHistory(end) = [];
            app.ManualReferenceMask = previousState.Mask;
            app.AnnotationStrokeCount = previousState.StrokeCount;
            app.storeCurrentAnnotation();
            app.clearAnnotationMetrics();
            app.refreshAnnotationView();
        end

        function clearAnnotation(app)
            if isempty(app.OriginalImage)
                return;
            end
            app.AnnotationDrawing = false;
            app.AnnotationLastPoint = [];
            previousState = struct( ...
                'Mask', app.ManualReferenceMask, ...
                'StrokeCount', app.AnnotationStrokeCount);
            app.AnnotationHistory{end + 1, 1} = previousState;
            app.ManualReferenceMask = false( ...
                size(app.OriginalImage, 1), size(app.OriginalImage, 2));
            app.AnnotationStrokeCount = 0;
            app.storeCurrentAnnotation();
            app.clearAnnotationMetrics();
            app.refreshAnnotationView();
        end

        function storeCurrentAnnotation(app)
            if app.CurrentImageIndex >= 1 && ...
                    app.CurrentImageIndex <= numel(app.CachedManualReferenceMasks)
                app.CachedManualReferenceMasks{app.CurrentImageIndex} = ...
                    app.ManualReferenceMask;
                app.CachedAnnotationStrokeCounts(app.CurrentImageIndex) = ...
                    app.AnnotationStrokeCount;
            end
        end

        function refreshAnnotationView(app)
            if isempty(app.OriginalImage)
                app.showAxesMessage(app.AnnotationAxes, ...
                    "Manual Crack Annotation", "Load an image to begin");
                return;
            end
            if isempty(app.ManualReferenceMask)
                app.ManualReferenceMask = false( ...
                    size(app.OriginalImage, 1), size(app.OriginalImage, 2));
            end
            displayImage = app.ensureDisplayRgb(app.OriginalImage);
            mask = logical(app.ManualReferenceMask);
            alpha = 0.62;
            annotationColour = reshape([1.00 0.14 0.52], 1, 1, 3);
            for channel = 1:3
                layer = displayImage(:, :, channel);
                layer(mask) = (1 - alpha) .* layer(mask) + ...
                    alpha .* annotationColour(1, 1, channel);
                displayImage(:, :, channel) = layer;
            end
            if isempty(app.AnnotationImageHandle) || ...
                    ~isvalid(app.AnnotationImageHandle) || ...
                    ~isequal(size(app.AnnotationImageHandle.CData), ...
                    size(displayImage))
                cla(app.AnnotationAxes);
                app.AnnotationImageHandle = imshow(displayImage, ...
                    "Parent", app.AnnotationAxes);
                app.AnnotationImageHandle.HitTest = "on";
                app.AnnotationImageHandle.PickableParts = "all";
                app.AnnotationImageHandle.ButtonDownFcn = ...
                    @app.handleAnnotationButtonDown;
                app.AnnotationAxes.ButtonDownFcn = ...
                    @app.handleAnnotationButtonDown;
                app.AnnotationZoomIndex = 1;
                app.applyAnnotationZoom([]);
            else
                app.AnnotationImageHandle.CData = displayImage;
            end
            title(app.AnnotationAxes, ...
                "Manual Crack Annotation", "FontWeight", "bold");
            app.updateAnnotationSummary();
        end

        function updateAnnotationSummary(app)
            if isempty(app.ManualReferenceMask)
                coverage = 0;
            else
                coverage = 100 .* nnz(app.ManualReferenceMask) ./ ...
                    numel(app.ManualReferenceMask);
            end
            app.AnnotationCoverageLabel.Text = sprintf( ...
                'Crack coverage: %.2f%%', coverage);
            app.AnnotationStrokeLabel.Text = sprintf( ...
                'Strokes: %d', app.AnnotationStrokeCount);
        end

        function clearAnnotationMetrics(app)
            app.AnnotationMetricsTable.Data(:, 2) = ...
                {'--'; '--'; '--'; '--'};
        end

        function saveAnnotationMask(app)
            if isempty(app.ManualReferenceMask) || isempty(app.CurrentImagePath)
                uialert(app.UIFigure, ...
                    "Create an annotation before saving.", "No annotation");
                return;
            end
            [sourceFolder, sourceName] = fileparts(app.CurrentImagePath);
            [fileName, folderName] = uiputfile('*.png', ...
                "Save manual crack mask", ...
                fullfile(sourceFolder, sourceName + "_manual_mask.png"));
            if isequal(fileName, 0)
                return;
            end
            imwrite(uint8(app.ManualReferenceMask) .* 255, ...
                fullfile(folderName, fileName));
            app.ModelStatusLabel.Text = "Manual mask saved";
        end

        function compareAnnotation(app)
            if isempty(app.ManualReferenceMask) || nnz(app.ManualReferenceMask) == 0
                uialert(app.UIFigure, ...
                    "Draw a manual crack reference before comparison.", ...
                    "Empty annotation");
                return;
            end
            if isempty(app.AIPredictionMask)
                uialert(app.UIFigure, ...
                    "Run image analysis before comparison.", ...
                    "No DL prediction");
                return;
            end
            referenceMask = logical(app.ManualReferenceMask);
            predictionMask = app.matchMaskSize(app.AIPredictionMask);
            truePositive = nnz(predictionMask & referenceMask);
            falsePositive = nnz(predictionMask & ~referenceMask);
            falseNegative = nnz(~predictionMask & referenceMask);
            precision = app.safeRatio(truePositive, truePositive + falsePositive);
            recall = app.safeRatio(truePositive, truePositive + falseNegative);
            f1 = app.safeRatio(2 .* precision .* recall, precision + recall);
            iou = app.safeRatio(truePositive, ...
                truePositive + falsePositive + falseNegative);
            data = app.AnnotationMetricsTable.Data;
            data{1, 2} = sprintf('%.4f', precision);
            data{2, 2} = sprintf('%.4f', recall);
            data{3, 2} = sprintf('%.4f', f1);
            data{4, 2} = sprintf('%.4f', iou);
            app.AnnotationMetricsTable.Data = data;
        end

        function refreshStatistics(app)
            drawnow limitrate;
            app.resizeStatisticsCaseColumns();
            completed = find(app.AnalysisCompleted & ...
                ~cellfun(@isempty, app.CachedAIProbabilityMaps));
            imageCount = numel(app.ImageFiles);
            completedCount = numel(completed);
            app.StatisticsBatchLabel.Text = sprintf( ...
                'Analysed: %d / %d', completedCount, imageCount);
            if completedCount == 0
                app.showAxesMessage(app.StatisticsComparisonAxes, ...
                    "DL vs Classical", "No completed results");
                app.StatisticsCaseTable.Data = cell(0, 5);
                app.StatisticsCaseImageIndices = zeros(0, 1);
                app.resetStatisticsDisplay(imageCount);
                return;
            end

            app.StatisticsRefreshButton.Enable = "off";
            app.ModelStatusLabel.Text = "Building folder statistics from cache";
            drawnow;
            coverage = nan(completedCount, 1);
            classicalCoverage = nan(completedCount, 1);
            aiPrecision = nan(completedCount, 1);
            aiRecall = nan(completedCount, 1);
            aiF1 = nan(completedCount, 1);
            aiIoU = nan(completedCount, 1);
            classicalPrecision = nan(completedCount, 1);
            classicalRecall = nan(completedCount, 1);
            classicalF1 = nan(completedCount, 1);
            classicalIoU = nan(completedCount, 1);
            aiLatency = app.CachedAIElapsedSeconds(completed);
            classicalLatency = app.CachedClassicalElapsedSeconds(completed);
            displayNames = strings(completedCount, 1);
            hasGroundTruth = false(completedCount, 1);

            for row = 1:completedCount
                imageIndex = completed(row);
                probability = double( ...
                    app.CachedAIProbabilityMaps{imageIndex}) ./ 255;
                aiMask = probability >= app.CurrentThreshold;
                coverage(row) = 100 .* nnz(aiMask) ./ numel(aiMask);
                [~, name, extension] = fileparts(app.ImageFiles(imageIndex));
                displayNames(row) = name + extension;

                classicalMask = [];
                if imageIndex <= ...
                        numel(app.CachedClassicalPredictionMasks) && ...
                        ~isempty(app.CachedClassicalPredictionMasks{imageIndex})
                    classicalMask = logical( ...
                        app.CachedClassicalPredictionMasks{imageIndex});
                    classicalCoverage(row) = 100 .* nnz(classicalMask) ./ ...
                        numel(classicalMask);
                end

                if imageIndex <= numel(app.GroundTruthFiles) && ...
                        strlength(app.GroundTruthFiles(imageIndex)) > 0 && ...
                        isfile(app.GroundTruthFiles(imageIndex))
                    referenceMask = app.readMaskForSize( ...
                        app.GroundTruthFiles(imageIndex), size(aiMask));
                    [aiPrecision(row), aiRecall(row), ...
                        aiF1(row), aiIoU(row)] = ...
                        app.calculateMaskMetrics(aiMask, referenceMask);
                    hasGroundTruth(row) = true;
                    if ~isempty(classicalMask)
                        if ~isequal(size(classicalMask), size(referenceMask))
                            classicalMask = imresize(classicalMask, ...
                                size(referenceMask), 'nearest');
                        end
                        [classicalPrecision(row), classicalRecall(row), ...
                            classicalF1(row), classicalIoU(row)] = ...
                            app.calculateMaskMetrics( ...
                            classicalMask, referenceMask);
                    end
                end
                if mod(row, 100) == 0
                    app.StatisticsBatchLabel.Text = sprintf( ...
                        'Statistics: %d / %d', row, completedCount);
                    drawnow limitrate;
                end
            end

            app.plotMetricComparisonStatistics(aiPrecision, aiRecall, ...
                aiF1, aiIoU, classicalPrecision, classicalRecall, ...
                classicalF1, classicalIoU, hasGroundTruth);
            app.populateStatisticsCaseTable(displayNames, aiF1, ...
                classicalF1, hasGroundTruth, completed);
            app.updateStatisticsSummary(coverage, classicalCoverage, ...
                aiF1, classicalF1, aiLatency, classicalLatency, ...
                hasGroundTruth, completedCount, imageCount);
            app.StatisticsRefreshButton.Enable = "on";
            app.ModelStatusLabel.Text = sprintf( ...
                'Statistics ready | %d analysed images', completedCount);
        end

        function plotMetricComparisonStatistics(app, aiPrecision, aiRecall, ...
                aiF1, aiIoU, classicalPrecision, classicalRecall, ...
                classicalF1, classicalIoU, hasGroundTruth)
            ax = app.StatisticsComparisonAxes;
            paired = hasGroundTruth & isfinite(aiPrecision) & ...
                isfinite(aiRecall) & isfinite(aiF1) & isfinite(aiIoU) & ...
                isfinite(classicalPrecision) & isfinite(classicalRecall) & ...
                isfinite(classicalF1) & isfinite(classicalIoU);
            if ~any(paired)
                app.showAxesMessage(ax, "DL vs Classical", ...
                    "Ground Truth is required for accuracy metrics");
                return;
            end
            values = [ ...
                mean(aiPrecision(paired)), mean(classicalPrecision(paired)); ...
                mean(aiRecall(paired)), mean(classicalRecall(paired)); ...
                mean(aiF1(paired)), mean(classicalF1(paired)); ...
                mean(aiIoU(paired)), mean(classicalIoU(paired))];
            cla(ax);
            bars = bar(ax, values, "grouped");
            bars(1).FaceColor = [0.06 0.34 0.72];
            bars(2).FaceColor = [0.91 0.42 0.12];
            ax.XTick = 1:4;
            ax.XTickLabel = {'Precision', 'Recall', 'F1', 'IoU'};
            drawnow limitrate;
            for seriesIndex = 1:2
                text(ax, bars(seriesIndex).XEndPoints, ...
                    bars(seriesIndex).YEndPoints + 0.025, ...
                    compose('%.3f', values(:, seriesIndex)), ...
                    "HorizontalAlignment", "center", ...
                    "VerticalAlignment", "bottom", ...
                    "FontSize", 9, ...
                    "FontWeight", "bold", ...
                    "Color", bars(seriesIndex).FaceColor);
            end
            ylim(ax, [0 1.10]);
            ylabel(ax, "Mean score");
            title(ax, sprintf('Accuracy comparison | %d paired images', ...
                nnz(paired)), "FontWeight", "bold");
            legend(ax, {'DL', 'Classical'}, "Location", "northwest");
            grid(ax, "on");
        end

        function populateStatisticsCaseTable(app, names, aiF1, ...
                classicalF1, hasGroundTruth, completedIndices)
            gtRows = find(hasGroundTruth & isfinite(aiF1));
            [~, gtOrder] = sort(aiF1(gtRows), 'ascend');
            orderedRows = [gtRows(gtOrder); find(~hasGroundTruth)];
            if isempty(orderedRows)
                orderedRows = (1:numel(names))';
            end
            app.StatisticsCaseImageIndices = completedIndices(orderedRows);
            tableData = cell(numel(orderedRows), 5);
            for outputRow = 1:numel(orderedRows)
                sourceRow = orderedRows(outputRow);
                tableData{outputRow, 1} = char(names(sourceRow));
                if ~hasGroundTruth(sourceRow) || ~isfinite(aiF1(sourceRow))
                    tableData(outputRow, 2:4) = {'N/A', 'N/A', 'N/A'};
                    tableData{outputRow, 5} = 'No GT';
                    continue;
                end
                tableData{outputRow, 2} = sprintf('%.4f', aiF1(sourceRow));
                if isfinite(classicalF1(sourceRow))
                    deltaF1 = aiF1(sourceRow) - classicalF1(sourceRow);
                    tableData{outputRow, 3} = ...
                        sprintf('%.4f', classicalF1(sourceRow));
                    tableData{outputRow, 4} = sprintf('%+.4f', deltaF1);
                else
                    deltaF1 = NaN;
                    tableData{outputRow, 3} = 'N/A';
                    tableData{outputRow, 4} = 'N/A';
                end
                if aiF1(sourceRow) == 0
                    tableData{outputRow, 5} = 'Missed';
                elseif aiF1(sourceRow) < 0.40
                    tableData{outputRow, 5} = 'Low F1';
                elseif isfinite(deltaF1) && deltaF1 < -0.05
                    tableData{outputRow, 5} = 'DL worse';
                elseif isfinite(deltaF1) && deltaF1 > 0.15
                    tableData{outputRow, 5} = 'DL better';
                else
                    tableData{outputRow, 5} = 'Normal';
                end
            end
            app.StatisticsCaseTable.Data = tableData;
        end

        function openStatisticsCase(app, event)
            if isempty(event.Indices)
                return;
            end
            selectedRow = event.Indices(1, 1);
            if selectedRow < 1 || ...
                    selectedRow > numel(app.StatisticsCaseImageIndices)
                return;
            end
            targetImageIndex = app.StatisticsCaseImageIndices(selectedRow);
            app.CurrentImageIndex = targetImageIndex;
            app.loadCurrentImage();
            app.setMode("Analyse");
            app.ModelStatusLabel.Text = sprintf( ...
                'Opened review case | image %d / %d', ...
                targetImageIndex, numel(app.ImageFiles));
        end

        function updateStatisticsSummary(app, coverage, classicalCoverage, ...
                aiF1, classicalF1, aiLatency, classicalLatency, ...
                hasGroundTruth, completedCount, imageCount)
            app.StatisticsBatchLabel.Text = sprintf( ...
                'Analysed: %d / %d | GT: %d', ...
                completedCount, imageCount, nnz(hasGroundTruth));
            app.StatisticsAnalysedValueLabel.Text = sprintf( ...
                '%d / %d', completedCount, imageCount);
            app.StatisticsGTValueLabel.Text = sprintf('%d', nnz(hasGroundTruth));

            validAIF1 = aiF1(hasGroundTruth & isfinite(aiF1));
            validClassicalF1 = classicalF1( ...
                hasGroundTruth & isfinite(classicalF1));
            if isempty(validAIF1)
                app.StatisticsDLF1ValueLabel.Text = "N/A";
                app.StatisticsClassicalF1ValueLabel.Text = "N/A";
                zeroF1Text = "N/A";
            else
                app.StatisticsDLF1ValueLabel.Text = ...
                    sprintf('%.4f', mean(validAIF1));
                zeroF1Text = sprintf('%d', nnz(validAIF1 == 0));
                if isempty(validClassicalF1)
                    app.StatisticsClassicalF1ValueLabel.Text = "N/A";
                else
                    app.StatisticsClassicalF1ValueLabel.Text = ...
                        sprintf('%.4f', mean(validClassicalF1));
                end
            end

            validAILatency = aiLatency(isfinite(aiLatency) & aiLatency >= 0);
            validClassicalLatency = classicalLatency( ...
                isfinite(classicalLatency) & classicalLatency >= 0);
            if isempty(validAILatency)
                app.StatisticsDLTimeValueLabel.Text = "N/A";
                dlTimeText = "N/A";
            else
                meanDLTime = mean(validAILatency);
                app.StatisticsDLTimeValueLabel.Text = ...
                    sprintf('%.2f s', meanDLTime);
                dlTimeText = sprintf('%.3f s', meanDLTime);
            end
            if isempty(validClassicalLatency)
                classicalTimeText = "N/A";
            else
                classicalTimeText = sprintf('%.3f s', ...
                    mean(validClassicalLatency));
            end
            totalTime = sum(validAILatency) + sum(validClassicalLatency);
            validCoverage = coverage(isfinite(coverage));
            validClassicalCoverage = classicalCoverage( ...
                isfinite(classicalCoverage));
            if isempty(validCoverage)
                dlCoverageText = "N/A";
            else
                dlCoverageText = sprintf('%.2f%%', mean(validCoverage));
            end
            if isempty(validClassicalCoverage)
                classicalCoverageText = "N/A";
            else
                classicalCoverageText = sprintf( ...
                    '%.2f%%', mean(validClassicalCoverage));
            end
            data = app.StatisticsMetricsTable.Data;
            data{1, 2} = sprintf('%.1f s', totalTime);
            data{2, 2} = char(dlTimeText);
            data{3, 2} = char(classicalTimeText);
            data{4, 2} = char(zeroF1Text);
            data{5, 2} = char(dlCoverageText);
            data{6, 2} = char(classicalCoverageText);
            app.StatisticsMetricsTable.Data = data;
        end

        function resetStatisticsDisplay(app, imageCount)
            app.StatisticsAnalysedValueLabel.Text = sprintf('0 / %d', imageCount);
            app.StatisticsGTValueLabel.Text = "0";
            app.StatisticsDLF1ValueLabel.Text = "N/A";
            app.StatisticsClassicalF1ValueLabel.Text = "N/A";
            app.StatisticsDLTimeValueLabel.Text = "N/A";
            data = app.StatisticsMetricsTable.Data;
            data(:, 2) = {'--'; '--'; '--'; '--'; '--'; '--'};
            app.StatisticsMetricsTable.Data = data;
        end

        function mask = readMaskForSize(~, maskPath, targetSize)
            mask = imread(maskPath);
            if ndims(mask) == 3
                mask = rgb2gray(mask);
            end
            mask = mask > 0;
            if ~isequal(size(mask), targetSize)
                mask = imresize(mask, targetSize, 'nearest');
            end
            mask = logical(mask);
        end

        function [precision, recall, f1, iou] = ...
                calculateMaskMetrics(app, predictionMask, referenceMask)
            truePositive = nnz(predictionMask & referenceMask);
            falsePositive = nnz(predictionMask & ~referenceMask);
            falseNegative = nnz(~predictionMask & referenceMask);
            precision = app.safeRatio( ...
                truePositive, truePositive + falsePositive);
            recall = app.safeRatio( ...
                truePositive, truePositive + falseNegative);
            f1 = app.safeRatio(2 .* precision .* recall, precision + recall);
            iou = app.safeRatio(truePositive, ...
                truePositive + falsePositive + falseNegative);
        end

        function setMode(app, modeName)
            app.AnnotationDrawing = false;
            app.AnnotationLastPoint = [];
            app.CurrentMode = string(modeName);
            app.UIFigure.Pointer = "arrow";
            app.WorkspaceGrid.Visible = "off";
            app.InsightGrid.Visible = "off";
            app.AnnotationGrid.Visible = "off";
            app.AnnotationInsightGrid.Visible = "off";
            app.StatisticsGrid.Visible = "off";
            app.StatisticsInsightGrid.Visible = "off";
            switch app.CurrentMode
                case "Annotate"
                    app.UIFigure.Pointer = "crosshair";
                    app.AnnotationGrid.Visible = "on";
                    app.AnnotationInsightGrid.Visible = "on";
                    app.refreshAnnotationView();
                case "Statistics"
                    app.StatisticsGrid.Visible = "on";
                    app.StatisticsInsightGrid.Visible = "on";
                    app.refreshStatistics();
                otherwise
                    app.WorkspaceGrid.Visible = "on";
                    app.InsightGrid.Visible = "on";
            end
            inactive = [0.93 0.94 0.96];
            active = [0.08 0.36 0.72];
            app.AnalyseModeButton.BackgroundColor = inactive;
            app.AnnotateModeButton.BackgroundColor = inactive;
            app.StatisticsModeButton.BackgroundColor = inactive;
            app.AnalyseModeButton.FontColor = [0.20 0.23 0.28];
            app.AnnotateModeButton.FontColor = [0.20 0.23 0.28];
            app.StatisticsModeButton.FontColor = [0.20 0.23 0.28];
            app.AnalyseModeButton.FontWeight = "normal";
            app.AnnotateModeButton.FontWeight = "normal";
            app.StatisticsModeButton.FontWeight = "normal";

            switch app.CurrentMode
                case "Analyse"
                    selectedButton = app.AnalyseModeButton;
                case "Annotate"
                    selectedButton = app.AnnotateModeButton;
                otherwise
                    selectedButton = app.StatisticsModeButton;
            end
            selectedButton.BackgroundColor = active;
            selectedButton.FontColor = [1 1 1];
            selectedButton.FontWeight = "bold";
        end
    end
end
