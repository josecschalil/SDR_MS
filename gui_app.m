function gui_app()
% GUI_APP SDR AX.25 Digital Chat System GUI
%
% Provides user interface for:
%   - Device selection (TX/RX Pluto radios)
%   - Message input and transmission
%   - Chat display
%   - Status indication (IDLE/TX/RX)
%   - Half-duplex control

    % Create main figure
    fig = uifigure('Name', 'SDR AX.25 Chat System', ...
                   'Position', [100, 100, 800, 600], ...
                   'Color', [0.94 0.94 0.94]);
    
    % Initialize app data
    app = struct();
    app.fig = fig;
    app.stateMachine = half_duplex_sm();
    app.txSDR = [];
    app.rxSDR = [];
    app.availableRadios = [];
    app.rxTimer = [];
    app.sourceCall = 'N0CALL';
    app.destCall = 'CQ';
    
    % Create UI components
    createUIComponents(app);
    
    % Store app data
    fig.UserData = app;
    
    % Detect radios on startup
    detectRadios(fig);
end

function createUIComponents(app)
    fig = app.fig;
    
    % Title
    titleLabel = uilabel(fig, 'Position', [20, 560, 760, 30], ...
                         'Text', '📡 SDR AX.25 Digital Chat System', ...
                         'FontSize', 18, 'FontWeight', 'bold', ...
                         'HorizontalAlignment', 'center');
    
    %% Device Selection Panel
    devicePanel = uipanel(fig, 'Position', [20, 460, 760, 90], ...
                          'Title', 'SDR Device Selection', ...
                          'FontWeight', 'bold');
    
    % TX Radio
    uilabel(devicePanel, 'Position', [10, 40, 80, 22], ...
            'Text', 'TX Radio:');
    app.txRadioDropdown = uidropdown(devicePanel, ...
                                     'Position', [100, 40, 250, 22], ...
                                     'Items', {'No radios detected'}, ...
                                     'Value', 'No radios detected');
    
    % RX Radio
    uilabel(devicePanel, 'Position', [10, 10, 80, 22], ...
            'Text', 'RX Radio:');
    app.rxRadioDropdown = uidropdown(devicePanel, ...
                                     'Position', [100, 10, 250, 22], ...
                                     'Items', {'No radios detected'}, ...
                                     'Value', 'No radios detected');
    
    % Detect button
    app.detectButton = uibutton(devicePanel, 'push', ...
                                'Position', [370, 25, 100, 30], ...
                                'Text', '🔍 Detect', ...
                                'ButtonPushedFcn', @(btn,event) detectRadios(fig));
    
    % Connect button
    app.connectButton = uibutton(devicePanel, 'push', ...
                                 'Position', [480, 25, 100, 30], ...
                                 'Text', '🔌 Connect', ...
                                 'ButtonPushedFcn', @(btn,event) connectRadios(fig));
    
    % Status indicator
    app.statusLabel = uilabel(devicePanel, 'Position', [600, 20, 150, 40], ...
                              'Text', '⚪ IDLE', ...
                              'FontSize', 16, 'FontWeight', 'bold', ...
                              'HorizontalAlignment', 'center');
    
    %% Callsign Panel
    callPanel = uipanel(fig, 'Position', [20, 390, 760, 60], ...
                        'Title', 'Callsigns', 'FontWeight', 'bold');
    
    uilabel(callPanel, 'Position', [10, 10, 80, 22], ...
            'Text', 'Source:');
    app.sourceCallEdit = uieditfield(callPanel, 'text', ...
                                     'Position', [100, 10, 100, 22], ...
                                     'Value', 'N0CALL');
    
    uilabel(callPanel, 'Position', [220, 10, 80, 22], ...
            'Text', 'Dest:');
    app.destCallEdit = uieditfield(callPanel, 'text', ...
                                   'Position', [310, 10, 100, 22], ...
                                   'Value', 'CQ');
    
    %% Chat Display Panel
    chatPanel = uipanel(fig, 'Position', [20, 120, 760, 260], ...
                        'Title', 'Chat History', 'FontWeight', 'bold');
    
    app.chatDisplay = uitextarea(chatPanel, ...
                                 'Position', [10, 10, 740, 220], ...
                                 'Editable', 'off', ...
                                 'Value', {'System: Ready'});
    
    %% Message Input Panel
    inputPanel = uipanel(fig, 'Position', [20, 20, 760, 90], ...
                         'Title', 'Send Message', 'FontWeight', 'bold');
    
    app.messageEdit = uitextarea(inputPanel, ...
                                 'Position', [10, 10, 630, 50], ...
                                 'Value', {'Type your message here...'});
    
    app.requestTXButton = uibutton(inputPanel, 'push', ...
                                   'Position', [650, 35, 100, 30], ...
                                   'Text', '📢 Request TX', ...
                                   'ButtonPushedFcn', @(btn,event) requestTX(fig), ...
                                   'Enable', 'off');
    
    app.sendButton = uibutton(inputPanel, 'push', ...
                              'Position', [650, 5, 100, 25], ...
                              'Text', '📤 Send', ...
                              'ButtonPushedFcn', @(btn,event) sendMessage(fig), ...
                              'Enable', 'off', ...
                              'BackgroundColor', [0.3 0.75 0.3]);
end

function detectRadios(fig)
    app = fig.UserData;
    
    addChatMessage(fig, 'System: Detecting Pluto radios...');
    
    try
        % Detect radios
        app.availableRadios = pluto_config();
        
        if ~isempty(app.availableRadios)
            radioNames = cell(1, length(app.availableRadios));
            for i = 1:length(app.availableRadios)
                radioNames{i} = app.availableRadios(i).RadioID;
            end
            
            app.txRadioDropdown.Items = radioNames;
            app.txRadioDropdown.Value = radioNames{1};
            app.rxRadioDropdown.Items = radioNames;
            if length(radioNames) > 1
                app.rxRadioDropdown.Value = radioNames{2};
            else
                app.rxRadioDropdown.Value = radioNames{1};
            end
            
            addChatMessage(fig, sprintf('System: Found %d radio(s)', length(app.availableRadios)));
        else
            addChatMessage(fig, 'System: No Pluto radios detected');
            app.txRadioDropdown.Items = {'No radios'};
            app.rxRadioDropdown.Items = {'No radios'};
        end
    catch ME
        addChatMessage(fig, sprintf('System Error: %s', ME.message));
    end
    
    fig.UserData = app;
end

function connectRadios(fig)
    app = fig.UserData;
    
    if isempty(app.availableRadios)
        addChatMessage(fig, 'System: No radios available. Click Detect first.');
        return;
    end
    
    try
        txID = app.txRadioDropdown.Value;
        rxID = app.rxRadioDropdown.Value;
        
        addChatMessage(fig, sprintf('System: Connecting TX: %s, RX: %s...', txID, rxID));
        
        % Configure radios
        [app.txSDR, app.rxSDR, ~] = pluto_config(txID, rxID, 145e6, 0, 20);
        
        if ~isempty(app.txSDR) && ~isempty(app.rxSDR)
            addChatMessage(fig, 'System: ✓ Connected successfully!');
            app.requestTXButton.Enable = 'on';
            app.stateMachine.enterReceiveMode();
            updateStatus(fig);
            
            % Start RX monitoring
            startRXMonitoring(fig);
        else
            addChatMessage(fig, 'System: ✗ Connection failed');
        end
    catch ME
        addChatMessage(fig, sprintf('System Error: %s', ME.message));
    end
    
    fig.UserData = app;
end

function requestTX(fig)
    app = fig.UserData;
    
    if app.stateMachine.requestTransmit()
        addChatMessage(fig, 'System: TX granted');
        app.sendButton.Enable = 'on';
        app.requestTXButton.Enable = 'off';
        updateStatus(fig);
    else
        addChatMessage(fig, 'System: TX denied (already transmitting)');
    end
    
    fig.UserData = app;
end

function sendMessage(fig)
    app = fig.UserData;
    
    message = strjoin(app.messageEdit.Value, ' ');
    
    if isempty(strtrim(message)) || strcmp(message, 'Type your message here...')
        addChatMessage(fig, 'System: Please enter a message');
        return;
    end
    
    % Get callsigns
    sourceCall = app.sourceCallEdit.Value;
    destCall = app.destCallEdit.Value;
    
    addChatMessage(fig, sprintf('You → %s: %s', destCall, message));
    
    % Transmit
    success = tx_chain(message, app.txSDR, sourceCall, destCall);
    
    if success
        addChatMessage(fig, 'System: Message sent ✓');
    else
        addChatMessage(fig, 'System: Transmission failed ✗');
    end
    
    % Clear message box
    app.messageEdit.Value = {''};
    
    % Return to RX mode
    app.stateMachine.finishTransmit();
    app.sendButton.Enable = 'off';
    app.requestTXButton.Enable = 'on';
    updateStatus(fig);
    
    fig.UserData = app;
end

function startRXMonitoring(fig)
    app = fig.UserData;
    
    % Create timer for periodic RX checks
    if ~isempty(app.rxTimer)
        stop(app.rxTimer);
        delete(app.rxTimer);
    end
    
    app.rxTimer = timer('ExecutionMode', 'fixedRate', ...
                        'Period', 2, ...
                        'TimerFcn', @(~,~) checkForMessages(fig));
    start(app.rxTimer);
    
    fig.UserData = app;
end

function checkForMessages(fig)
    if ~isvalid(fig)
        return;
    end
    
    app = fig.UserData;
    
    if isempty(app.rxSDR) || ~app.stateMachine.canReceive()
        return;
    end
    
    try
        % Quick RX check (1 second)
        [message, valid, sourceCall, ~] = rx_chain(app.rxSDR, 1);
        
        if valid && ~isempty(message)
            addChatMessage(fig, sprintf('%s: %s', sourceCall, strtrim(message)));
        end
    catch
        % Ignore RX errors
    end
end

function addChatMessage(fig, message)
    app = fig.UserData;
    timestamp = datestr(now, 'HH:MM:SS');
    newMsg = sprintf('[%s] %s', timestamp, message);
    app.chatDisplay.Value = [app.chatDisplay.Value; {newMsg}];
    
    % Auto-scroll to bottom
    scroll(app.chatDisplay, 'bottom');
    
    fig.UserData = app;
end

function updateStatus(fig)
    app = fig.UserData;
    app.statusLabel.Text = app.stateMachine.getStateString();
    fig.UserData = app;
end
