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
    app.pingPending = false;
    app.pingId = 0;
    app.pingStart = 0;
    [app.logFile, app.instanceId] = initLogFile();
    
    % Create UI components
    app = createUIComponents(app);
    
    % Store app data
    fig.UserData = app;
    writeLog(fig, 'INFO', 'APP_START', 'GUI initialized');
    
    % Detect radios on startup
    detectRadios(fig);
end

function app = createUIComponents(app)
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
                                 'Position', [10, 10, 520, 50], ...
                                 'Value', {'Type your message here...'});
    
    app.requestTXButton = uibutton(inputPanel, 'push', ...
                                   'Position', [540, 35, 100, 30], ...
                                   'Text', '📢 Request TX', ...
                                   'ButtonPushedFcn', @(btn,event) requestTX(fig), ...
                                   'Enable', 'off');
    
    app.pingButton = uibutton(inputPanel, 'push', ...
                              'Position', [650, 35, 100, 30], ...
                              'Text', '🔔 Ping Peer', ...
                              'ButtonPushedFcn', @(btn,event) pingPeer(fig), ...
                              'Enable', 'off');
    
    app.sendButton = uibutton(inputPanel, 'push', ...
                              'Position', [540, 5, 210, 25], ...
                              'Text', '📤 Send', ...
                              'ButtonPushedFcn', @(btn,event) sendMessage(fig), ...
                              'Enable', 'off', ...
                              'BackgroundColor', [0.3 0.75 0.3]);
    
    % Return updated app structure
end

function detectRadios(fig)
    app = fig.UserData;
    writeLog(fig, 'INFO', 'DETECT_START', 'Detecting Pluto radios');
    
    addChatMessage(fig, 'System: Detecting Pluto radios...');
    
    try
        % Detect radios (get third output - availableRadios)
        [~, ~, app.availableRadios] = pluto_config();
        
        if ~isempty(app.availableRadios)
            radioNames = cell(1, length(app.availableRadios));
            for i = 1:length(app.availableRadios)
                radioNames{i} = app.availableRadios(i).RadioID;
            end
            writeLog(fig, 'INFO', 'DETECT_FOUND', sprintf('Found %d radio(s): %s', length(app.availableRadios), strjoin(radioNames, ',')));
            
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
            writeLog(fig, 'WARN', 'DETECT_NONE', 'No Pluto radios detected');
            app.txRadioDropdown.Items = {'No radios'};
            app.rxRadioDropdown.Items = {'No radios'};
        end
    catch ME
        writeLog(fig, 'ERROR', 'DETECT_ERROR', ME.message);
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
        writeLog(fig, 'INFO', 'CONNECT_START', sprintf('TX=%s RX=%s', txID, rxID));
        
        addChatMessage(fig, sprintf('System: Connecting TX: %s, RX: %s...', txID, rxID));
        
        % Configure radios
        [app.txSDR, app.rxSDR, ~] = pluto_config(txID, rxID, 433e6, 0, 20);
        
        if ~isempty(app.txSDR) && ~isempty(app.rxSDR)
            addChatMessage(fig, 'System: ✓ Connected successfully!');
            writeLog(fig, 'INFO', 'CONNECT_OK', 'Connected successfully');
            app.requestTXButton.Enable = 'on';
            app.pingButton.Enable = 'on';
            app.stateMachine.enterReceiveMode();
            updateStatus(fig);
            
            % Start RX monitoring
            startRXMonitoring(fig);
        else
            addChatMessage(fig, 'System: ✗ Connection failed');
            writeLog(fig, 'ERROR', 'CONNECT_FAIL', 'Connection returned empty SDR handle(s)');
        end
    catch ME
        writeLog(fig, 'ERROR', 'CONNECT_ERROR', ME.message);
        addChatMessage(fig, sprintf('System Error: %s', ME.message));
    end
    
    fig.UserData = app;
end

function requestTX(fig)
    app = fig.UserData;
    try
        if app.stateMachine.canTransmit() && strcmp(app.sendButton.Enable, 'off')
            % Recover from a stale TX lock left by a previous error path.
            app.stateMachine.finishTransmit();
        end

        if strcmp(app.requestTXButton.Enable, 'off') && ~app.stateMachine.canTransmit()
            app.requestTXButton.Enable = 'on';
        end

        addChatMessage(fig, 'System: Requesting TX...');
        writeLog(fig, 'INFO', 'TX_REQUEST', sprintf('stateBefore=%s', app.stateMachine.state));
        if app.stateMachine.requestTransmit()
            addChatMessage(fig, 'System: TX granted');
            writeLog(fig, 'INFO', 'TX_GRANTED', 'Transmission permission granted');
            app.sendButton.Enable = 'on';
            app.requestTXButton.Enable = 'off';
            updateStatus(fig);
        else
            addChatMessage(fig, 'System: TX denied (already transmitting)');
            writeLog(fig, 'WARN', 'TX_DENIED', sprintf('state=%s', app.stateMachine.state));
        end
    catch ME
        writeLog(fig, 'ERROR', 'TX_REQUEST_ERROR', ME.message);
        addChatMessage(fig, sprintf('Request TX error: %s', ME.message));
    end
    fig.UserData = app;
end

function sendMessage(fig)
    app = fig.UserData;
    try
        message = strjoin(app.messageEdit.Value, ' ');
        writeLog(fig, 'INFO', 'SEND_START', sprintf('msgLen=%d', strlength(message)));
        
        if isempty(strtrim(message)) || strcmp(message, 'Type your message here...')
            addChatMessage(fig, 'System: Please enter a message');
            return;
        end
        
        % Get callsigns
        sourceCall = app.sourceCallEdit.Value;
        destCall = app.destCallEdit.Value;
        
        addChatMessage(fig, sprintf('You → %s: %s', destCall, message));
        writeLog(fig, 'INFO', 'SEND_TX_CHAIN', sprintf('src=%s dst=%s msg="%s"', sourceCall, destCall, message));
        
        % Transmit
        success = tx_chain(message, app.txSDR, sourceCall, destCall);
        
        if success
            addChatMessage(fig, 'System: Message sent ✓');
            writeLog(fig, 'INFO', 'SEND_OK', 'Message transmitted successfully');
        else
            addChatMessage(fig, 'System: Transmission failed ✗');
            writeLog(fig, 'ERROR', 'SEND_FAIL', 'tx_chain returned false');
        end
        
        % Clear message box
        app.messageEdit.Value = {''};
        
        % Return to RX mode
        app.stateMachine.finishTransmit();
        app.sendButton.Enable = 'off';
        app.requestTXButton.Enable = 'on';
        updateStatus(fig);
    catch ME
        if app.stateMachine.canTransmit()
            app.stateMachine.finishTransmit();
        end
        app.sendButton.Enable = 'off';
        app.requestTXButton.Enable = 'on';
        updateStatus(fig);
        writeLog(fig, 'ERROR', 'SEND_ERROR', ME.message);
        addChatMessage(fig, sprintf('Send error: %s', ME.message));
    end
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
    writeLog(fig, 'INFO', 'RX_TIMER_START', 'RX monitor timer started (period=2s)');
    
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
        % Quick RX check (2 seconds to reduce missed bursts)
        [message, valid, sourceCall, ~] = rx_chain(app.rxSDR, 2);
        
        if valid && ~isempty(message)
            msgTrim = strtrim(message);
            
            % Handle ping replies/requests
            if handlePingReply(fig, msgTrim, sourceCall)
                writeLog(fig, 'INFO', 'RX_PONG_HANDLED', sprintf('source=%s msg="%s"', sourceCall, msgTrim));
                return;
            end
            
            if handlePingRequest(fig, msgTrim, sourceCall)
                writeLog(fig, 'INFO', 'RX_PING_HANDLED', sprintf('source=%s msg="%s"', sourceCall, msgTrim));
                return;
            end
            
            writeLog(fig, 'INFO', 'RX_MESSAGE', sprintf('source=%s msg="%s"', sourceCall, msgTrim));
            addChatMessage(fig, sprintf('%s: %s', sourceCall, msgTrim));
        end
    catch ME
        writeLog(fig, 'ERROR', 'RX_ERROR', ME.message);
        % Ignore RX errors
    end
end

function addChatMessage(fig, message)
    app = fig.UserData;
    timestamp = datestr(now, 'HH:MM:SS');
    newMsg = sprintf('[%s] %s', timestamp, message);
    app.chatDisplay.Value = [app.chatDisplay.Value; {newMsg}];
    writeLog(fig, 'CHAT', 'CHAT_MESSAGE', message);
    
    % Auto-scroll to bottom
    scroll(app.chatDisplay, 'bottom');
    
    fig.UserData = app;
end

function updateStatus(fig)
    app = fig.UserData;
    app.statusLabel.Text = app.stateMachine.getStateString();
    writeLog(fig, 'INFO', 'STATE_UPDATE', sprintf('state=%s statusLabel=%s', app.stateMachine.state, app.statusLabel.Text));
    fig.UserData = app;
end

function pingPeer(fig)
    app = fig.UserData;
    try
        addChatMessage(fig, 'System: Preparing ping...');
        writeLog(fig, 'INFO', 'PING_START', 'Preparing ping');
        
        if isempty(app.txSDR) || isempty(app.rxSDR)
            addChatMessage(fig, 'System: Connect radios before pinging');
            return;
        end
        
        if ~app.stateMachine.requestTransmit()
            addChatMessage(fig, 'System: TX busy. Try again.');
            writeLog(fig, 'WARN', 'PING_TX_BUSY', sprintf('state=%s', app.stateMachine.state));
            return;
        end
        
        app.pingId = randi([0, 1e6]);
        app.pingStart = tic;
        app.pingPending = true;
        updateStatus(fig);
        fig.UserData = app;
        
        src = app.sourceCallEdit.Value;
        dst = app.destCallEdit.Value;
        
        addChatMessage(fig, sprintf('System: PING → %s', dst));
        writeLog(fig, 'INFO', 'PING_TX', sprintf('dst=%s pingId=%d', dst, app.pingId));
        success = tx_chain(sprintf('PING:%d', app.pingId), app.txSDR, src, dst);
        
        app = fig.UserData;
        
        if success
            addChatMessage(fig, 'System: Ping sent. Waiting for reply...');
            writeLog(fig, 'INFO', 'PING_SENT', sprintf('pingId=%d', app.pingId));
        else
            addChatMessage(fig, 'System: Ping transmit failed');
            writeLog(fig, 'ERROR', 'PING_SEND_FAIL', sprintf('pingId=%d', app.pingId));
            app.pingPending = false;
        end
        
        app.stateMachine.finishTransmit();
        updateStatus(fig);
        fig.UserData = app;
    catch ME
        if app.stateMachine.canTransmit()
            app.stateMachine.finishTransmit();
        end
        app.sendButton.Enable = 'off';
        app.requestTXButton.Enable = 'on';
        updateStatus(fig);
        fig.UserData = app;
        writeLog(fig, 'ERROR', 'PING_ERROR', ME.message);
        addChatMessage(fig, sprintf('Ping error: %s', ME.message));
    end
end

function handled = handlePingReply(fig, msgTrim, sourceCall)
    handled = false;
    app = fig.UserData;
    
    if startsWith(msgTrim, 'PONG:')
        parts = split(msgTrim, ':');
        pongId = NaN;
        if numel(parts) >= 2
            pongId = str2double(parts{2});
        end
        
        if app.pingPending && ~isnan(pongId) && pongId == app.pingId
            rttMs = round(toc(app.pingStart) * 1000);
            writeLog(fig, 'INFO', 'PING_RTT', sprintf('source=%s pingId=%d rttMs=%d', sourceCall, pongId, rttMs));
            addChatMessage(fig, sprintf('System: Pong from %s in %d ms', sourceCall, rttMs));
            app.pingPending = false;
            fig.UserData = app;
            handled = true;
        end
    end
end

function handled = handlePingRequest(fig, msgTrim, sourceCall)
    handled = false;
    
    if startsWith(msgTrim, 'PING:')
        parts = split(msgTrim, ':');
        pingId = '';
        if numel(parts) >= 2
            pingId = strtrim(parts{2});
        end
        
        addChatMessage(fig, sprintf('System: Ping request from %s (id %s)', sourceCall, pingId));
        sendPong(fig, sourceCall, pingId);
        handled = true;
    end
end

function sendPong(fig, destCall, pingId)
    app = fig.UserData;
    
    if isempty(app.txSDR)
        return;
    end
    
    if ~app.stateMachine.requestTransmit()
        addChatMessage(fig, 'System: Busy, unable to answer ping right now');
        writeLog(fig, 'WARN', 'PONG_BUSY', sprintf('dest=%s pingId=%s', destCall, pingId));
        return;
    end
    
    src = app.sourceCallEdit.Value;
    ackMsg = sprintf('PONG:%s', pingId);
    success = tx_chain(ackMsg, app.txSDR, src, destCall);
    
    if success
        addChatMessage(fig, sprintf('System: Pong → %s', destCall));
        writeLog(fig, 'INFO', 'PONG_SENT', sprintf('dest=%s pingId=%s', destCall, pingId));
    else
        addChatMessage(fig, sprintf('System: Failed to respond to ping from %s', destCall));
        writeLog(fig, 'ERROR', 'PONG_FAIL', sprintf('dest=%s pingId=%s', destCall, pingId));
    end
    
    app.stateMachine.finishTransmit();
    updateStatus(fig);
    fig.UserData = app;
end

function [logFile, instanceId] = initLogFile()
    timestamp = datestr(now, 'yyyymmdd_HHMMSSFFF');
    pid = feature('getpid');
    uniqueSuffix = randi([1000, 9999]);
    instanceId = sprintf('pid%d_%s_%d', pid, timestamp, uniqueSuffix);
    logDir = fullfile(pwd, 'logs');
    if ~exist(logDir, 'dir')
        mkdir(logDir);
    end
    logFile = fullfile(logDir, sprintf('gui_app_%s.txt', instanceId));
    fid = fopen(logFile, 'a');
    if fid ~= -1
        fprintf(fid, '=== GUI APP LOG START ===\n');
        fprintf(fid, 'time=%s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF'));
        fprintf(fid, 'instance=%s\n', instanceId);
        fprintf(fid, 'cwd=%s\n', pwd);
        fprintf(fid, '=========================\n');
        fclose(fid);
    end
end

function writeLog(fig, level, eventName, details)
    if nargin < 4
        details = '';
    end

    try
        app = fig.UserData;
        if isempty(app) || ~isfield(app, 'logFile') || isempty(app.logFile)
            return;
        end

        fid = fopen(app.logFile, 'a');
        if fid == -1
            return;
        end

        ts = datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF');
        stateText = 'NA';
        if isfield(app, 'stateMachine') && ~isempty(app.stateMachine)
            stateText = app.stateMachine.state;
        end

        details = char(string(details));
        details = strrep(details, sprintf('\n'), '\\n');
        details = strrep(details, sprintf('\r'), '');
        fprintf(fid, '[%s] [%s] [%s] [state=%s] %s\n', ts, level, eventName, stateText, details);
        fclose(fid);
    catch
        % Logging must never break app behavior.
    end
end
