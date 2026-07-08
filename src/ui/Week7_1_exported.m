classdef Week7_1_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure         matlab.ui.Figure
        Btn_Clear        matlab.ui.control.Button
        Lbl_Status       matlab.ui.control.Label
        Btn_Save         matlab.ui.control.Button
        Btn_Process      matlab.ui.control.Button
        Btn_Load         matlab.ui.control.Button
        UIAxes_Result    matlab.ui.control.UIAxes
        UIAxes_Original  matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        OriginalImage      % Store original image (uint8)
        ResultMask         % Store binary crack mask (logical)
        ImagePath          % Store image file path (string)
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: Btn_Load
        function Btn_LoadPushed(app, event)
            [filename, pathname] = uigetfile({'*.jpg;*.png;*.tif;*.bmp','Image Files'}, ...
                'Select Pavement Crack Image');
            if isequal(filename, 0)
                return;  % User cancelled
            end

            % Read the image
            app.ImagePath = fullfile(pathname, filename);
            try
                img = imread(app.ImagePath);
            catch ME
                uialert(app.UIFigure, ['Failed to read image: ' ME.message], 'Load Error');
                return;
            end

            % Store and display the image
            app.OriginalImage = img;
            imshow(img, 'Parent', app.UIAxes_Original);
            title(app.UIAxes_Original, 'Original Pavement');

            % Clear result area
            cla(app.UIAxes_Result);
            app.ResultMask = [];

            % Update status
            app.Lbl_Status.Text = 'Image loaded. Ready for classical detection.';
            app.Btn_Process.Enable = 'on';
            app.Btn_Save.Enable = 'off';
          
        end

        % Button pushed function: Btn_Process
        function Btn_ProcessPushed(app, event)
            % Check if image is loaded
            if isempty(app.OriginalImage)
                uialert(app.UIFigure, 'Please load an image first!', 'No Image');
                return;
            end

            app.Lbl_Status.Text = 'Processing (Classical Pipeline)...';
            drawnow;  % Force UI refresh

            % ============ Classical Pipeline (Built-in) ============
            I = app.OriginalImage;

            % 1. Convert to grayscale
            if size(I, 3) == 3
                Igray = rgb2gray(I);
            else
                Igray = I;
            end

            % 2. Gaussian smoothing (noise suppression)
            Ismooth = imgaussfilt(Igray, 1.5);

            % 3. CLAHE (handles illumination variation)
            Iclahe = adapthisteq(Ismooth, 'NumTiles', [8 8], 'ClipLimit', 0.02);

            % 4. Adaptive thresholding (Sauvola-style local threshold)
            T = adaptthresh(Iclahe, 0.45, 'NeighborhoodSize', 51);
            BW = imbinarize(Iclahe, T);

            % 5. Morphological cleaning (remove small noise blobs)
            BW = bwareaopen(BW, 30);

            % 6. Skeletonization (extract crack centerlines)
            BW_skel = bwmorph(BW, 'thin', Inf);

            % 7. Spur pruning (remove short branches to suppress texture noise)
            mask = bwmorph(BW_skel, 'spur', 15);
            % ========================================================

            % Store and display result
            app.ResultMask = mask;
            imshow(mask, 'Parent', app.UIAxes_Result);
            title(app.UIAxes_Result, 'Classical Output (Crack Mask)');
            colormap(app.UIAxes_Result, 'gray');

            app.Lbl_Status.Text = 'Detection complete! Result ready to save.';
            app.Btn_Save.Enable = 'on';
            %Once the classical team delivers classical_pipeline.m, simply replace lines % 1. Convert... through % 7. Spur... with:mask = classical_pipeline(I);
        end

        % Button pushed function: Btn_Save
        function Btn_SavePushed(app, event)
            % Check if result exists
            if isempty(app.ResultMask)
                uialert(app.UIFigure, 'No result to save. Please run detection first.', 'Warning');
                return;
            end

            % Open save dialog
            [filename, pathname] = uiputfile({'*.png','PNG Image'; '*.jpg','JPEG Image'}, ...
                'Save Crack Mask');
            if isequal(filename, 0)
                return;
            end

            % Save the mask
            imwrite(app.ResultMask, fullfile(pathname, filename));
            app.Lbl_Status.Text = ['Saved as: ' filename];
          
        end

        % Button pushed function: Btn_Clear
        function Btn_ClearPushed(app, event)
            % Clear all axes
            cla(app.UIAxes_Original);
            cla(app.UIAxes_Result);

            % Clear stored data
            app.OriginalImage = [];
            app.ResultMask = [];
            app.ImagePath = "";

            % Update status and buttons
            app.Lbl_Status.Text = 'All data cleared.';
            app.Btn_Process.Enable = 'off';
            app.Btn_Save.Enable = 'off';
        
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [1 1 1];
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';

            % Create UIAxes_Original
            app.UIAxes_Original = uiaxes(app.UIFigure);
            title(app.UIAxes_Original, 'Original')
            xlabel(app.UIAxes_Original, 'X')
            ylabel(app.UIAxes_Original, 'Y')
            zlabel(app.UIAxes_Original, 'Z')
            app.UIAxes_Original.FontName = 'Arial';
            app.UIAxes_Original.FontWeight = 'bold';
            app.UIAxes_Original.FontSizeMode = 'manual';
            app.UIAxes_Original.Position = [1 123 313 215];

            % Create UIAxes_Result
            app.UIAxes_Result = uiaxes(app.UIFigure);
            title(app.UIAxes_Result, 'Result')
            xlabel(app.UIAxes_Result, 'X')
            ylabel(app.UIAxes_Result, 'Y')
            zlabel(app.UIAxes_Result, 'Z')
            app.UIAxes_Result.FontName = 'Arial';
            app.UIAxes_Result.FontWeight = 'bold';
            app.UIAxes_Result.Position = [313 123 328 215];

            % Create Btn_Load
            app.Btn_Load = uibutton(app.UIFigure, 'push');
            app.Btn_Load.ButtonPushedFcn = createCallbackFcn(app, @Btn_LoadPushed, true);
            app.Btn_Load.BackgroundColor = [1 1 1];
            app.Btn_Load.FontName = 'Arial';
            app.Btn_Load.FontSize = 18;
            app.Btn_Load.FontWeight = 'bold';
            app.Btn_Load.FontColor = [0.149 0.549 0.8667];
            app.Btn_Load.Position = [14 398 115 30];
            app.Btn_Load.Text = 'Load image';

            % Create Btn_Process
            app.Btn_Process = uibutton(app.UIFigure, 'push');
            app.Btn_Process.ButtonPushedFcn = createCallbackFcn(app, @Btn_ProcessPushed, true);
            app.Btn_Process.BackgroundColor = [1 1 1];
            app.Btn_Process.FontName = 'Arial';
            app.Btn_Process.FontSize = 18;
            app.Btn_Process.FontWeight = 'bold';
            app.Btn_Process.FontColor = [0.149 0.549 0.8667];
            app.Btn_Process.Position = [146 437 180 30];
            app.Btn_Process.Text = 'Classical Detection';

            % Create Btn_Save
            app.Btn_Save = uibutton(app.UIFigure, 'push');
            app.Btn_Save.ButtonPushedFcn = createCallbackFcn(app, @Btn_SavePushed, true);
            app.Btn_Save.BackgroundColor = [1 1 1];
            app.Btn_Save.FontName = 'Arial';
            app.Btn_Save.FontSize = 18;
            app.Btn_Save.FontWeight = 'bold';
            app.Btn_Save.FontColor = [0.149 0.549 0.8667];
            app.Btn_Save.Position = [532 437 100 30];
            app.Btn_Save.Text = 'Save';

            % Create Lbl_Status
            app.Lbl_Status = uilabel(app.UIFigure);
            app.Lbl_Status.HorizontalAlignment = 'center';
            app.Lbl_Status.FontName = 'Arial';
            app.Lbl_Status.FontSize = 18;
            app.Lbl_Status.FontWeight = 'bold';
            app.Lbl_Status.FontColor = [0.149 0.549 0.8667];
            app.Lbl_Status.Position = [146 33 387 23];
            app.Lbl_Status.Text = 'Status';

            % Create Btn_Clear
            app.Btn_Clear = uibutton(app.UIFigure, 'push');
            app.Btn_Clear.ButtonPushedFcn = createCallbackFcn(app, @Btn_ClearPushed, true);
            app.Btn_Clear.BackgroundColor = [1 1 1];
            app.Btn_Clear.FontName = 'Arial';
            app.Btn_Clear.FontSize = 18;
            app.Btn_Clear.FontWeight = 'bold';
            app.Btn_Clear.FontColor = [0.149 0.549 0.8667];
            app.Btn_Clear.Position = [532 398 100 30];
            app.Btn_Clear.Text = 'Clear';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Week7_1_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end