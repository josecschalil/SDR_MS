function gui_simple()
% GUI_SIMPLE - Simplified GUI for SDR AX.25 Chat System
% 
% A minimal, robust GUI implementation that avoids common pitfalls

    % Create figure
    fig = figure('Name', 'SDR AX.25 Chat (Simple)', ...
                 'NumberTitle', 'off', ...
                 'Position', [100, 100, 700, 500], ...
                 'MenuBar', 'none', ...
                 'ToolBar', 'none', ...
                 'Color', [0.94 0.94 0.94]);
    
    % Initialize data
    data = struct();
    data.txSDR = [];
    data.rxSDR = [];
    data.radios = [];
    data.rxTimer = [];
    data.pingPending = false;
    data.pingId = 0;
    data.pingStart = 0;
    data.sm = half_duplex_sm();
    
    % Create UI elements
    % Title
    uicontrol('Style', 'text', ...
              'Position', [10, 460, 680, 30], ...
              'String', 'SDR AX.25 Digital Chat System', ...
              'FontSize', 14, 'FontWeight', 'bold', ...
              'BackgroundColor', [0.94 0.94 0.94]);
    
    % Status
    data.statusText = uicontrol('Style', 'text', ...
                                'Position', [10, 430, 680, 25], ...
                                'String', 'Status: IDLE', ...
                                'FontSize', 10, ...
                                'BackgroundColor', [0.9 0.9 0.9]);
    
    % Device selection
    uicontrol('Style', 'text', ...
              'Position', [10, 400, 100, 20], ...
              'String', 'TX Radio:', ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', [0.94 0.94 0.94]);
    data.txPopup = uicontrol('Style', 'popupmenu', ...
                             'Position', [120, 400, 200, 20], ...
                             'String', {'No radios'});
    
    uicontrol('Style', 'text', ...
              'Position', [10, 370, 100, 20], ...
              'String', 'RX Radio:', ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', [0.94 0.94 0.94]);
    data.rxPopup = uicontrol('Style', 'popupmenu', ...
                             'Position', [120, 370, 200, 20], ...
                             'String', {'No radios'});
    
    % Buttons
    uicontrol('Style', 'pushbutton', ...
              'Position', [340, 400, 80, 25], ...
              'String', 'Detect', ...
              'Callback', {@detectCallback, fig});
    
    uicontrol('Style', 'pushbutton', ...
              'Position', [430, 400, 80, 25], ...
              'String', 'Connect', ...
              'Callback', {@connectCallback, fig});
    
    % Callsigns
    uicontrol('Style', 'text', ...
              'Position', [10, 340, 80, 20], ...
              'String', 'Source Call:', ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', [0.94 0.94 0.94]);
    data.sourceEdit = uicontrol('Style', 'edit', ...
                                'Position', [100, 340, 100, 20], ...
                                'String', 'N0CALL');
    
    uicontrol('Style', 'text', ...
              'Position', [220, 340, 80, 20], ...
              'String', 'Dest Call:', ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', [0.94 0.94 0.94]);
    data.destEdit = uicontrol('Style', 'edit', ...
                              'Position', [310, 340, 100, 20], ...
                              'String', 'CQ');
    
    % Chat display
    uicontrol('Style', 'text', ...
              'Position', [10, 310, 680, 20], ...
              'String', 'Chat History:', ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', [0.94 0.94 0.94]);
    data.chatList = uicontrol('Style', 'listbox', ...
                              'Position', [10, 100, 680, 200], ...
                              'String', {'System: Ready'}, ...
                              'Max', 2);
    
    % Message input
    uicontrol('Style', 'text', ...
              'Position', [10, 70, 680, 20], ...
              'String', 'Message:', ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', [0.94 0.94 0.94]);
    data.msgEdit = uicontrol('Style', 'edit', ...
                             'Position', [10, 40, 420, 25], ...
                             'String', '', ...
                             'HorizontalAlignment', 'left');
    
    % Send buttons
    data.requestBtn = uicontrol('Style', 'pushbutton', ...
                                'Position', [440, 40, 80, 25], ...
                                'String', 'Request TX', ...
                                'Enable', 'off', ...
                                'Callback', {@requestTXCallback, fig});
    
    data.pingBtn = uicontrol('Style', 'pushbutton', ...
                             'Position', [530, 40, 80, 25], ...
                             'String', 'Ping', ...
                             'Enable', 'off', ...
                             'Callback', {@pingCallback, fig});
    
    data.sendBtn = uicontrol('Style', 'pushbutton', ...
                             'Position', [620, 10, 70, 25], ...
                             'String', 'Send', ...
                             'Enable', 'off', ...
                             'BackgroundColor', [0.3 0.75 0.3], ...
                             'Callback', {@sendCallback, fig});
    
    % Store data
    guidata(fig, data);
    
    % Add to chat
    addChat(fig, 'System: Click Detect to find Pluto radios');
end

function detectCallback(~, ~, fig)
    data = guidata(fig);
    addChat(fig, 'System: Detecting radios...');
    
    try
        [~, ~, radios] = pluto_config();
        data.radios = radios;
        
        if ~isempty(radios)
            names = cell(1, length(radios));
            for i = 1:length(radios)
                names{i} = radios(i).RadioID;
            end
            set(data.txPopup, 'String', names, 'Value', 1);
            if length(names) > 1
                set(data.rxPopup, 'String', names, 'Value', 2);
            else
                set(data.rxPopup, 'String', names, 'Value', 1);
            end
            addChat(fig, sprintf('System: Found %d radio(s)', length(radios)));
        else
            addChat(fig, 'System: No radios detected');
        end
        
        guidata(fig, data);
    catch ME
        addChat(fig, sprintf('Error: %s', ME.message));
    end
end

function connectCallback(~, ~, fig)
    data = guidata(fig);
    
    if isempty(data.radios)
        addChat(fig, 'System: No radios available');
        return;
    end
    
    try
        txIdx = get(data.txPopup, 'Value');
        rxIdx = get(data.rxPopup, 'Value');
        txID = data.radios(txIdx).RadioID;
        rxID = data.radios(rxIdx).RadioID;
        
        addChat(fig, sprintf('System: Connecting TX:%s RX:%s...', txID, rxID));
        
        [data.txSDR, data.rxSDR, ~] = pluto_config(txID, rxID, 433e6, 0, 20);
        
        if ~isempty(data.txSDR) && ~isempty(data.rxSDR)
            addChat(fig, 'System: Connected!');
            set(data.requestBtn, 'Enable', 'on');
            set(data.pingBtn, 'Enable', 'on');
            data.sm.enterReceiveMode();
            updateStatus(fig);
            startRXTimer(fig);
        else
            addChat(fig, 'System: Connection failed');
        end
        
        guidata(fig, data);
    catch ME
        addChat(fig, sprintf('Error: %s', ME.message));
    end
end

function requestTXCallback(~, ~, fig)
    data = guidata(fig);
    
    if data.sm.requestTransmit()
        addChat(fig, 'System: TX granted');
        set(data.sendBtn, 'Enable', 'on');
        set(data.requestBtn, 'Enable', 'off');
        updateStatus(fig);
    else
        addChat(fig, 'System: TX denied');
    end
    
    guidata(fig, data);
end

function sendCallback(~, ~, fig)
    data = guidata(fig);
    
    msg = get(data.msgEdit, 'String');
    if isempty(strtrim(msg))
        addChat(fig, 'System: Please enter a message');
        return;
    end
    
    src = get(data.sourceEdit, 'String');
    dst = get(data.destEdit, 'String');
    
    addChat(fig, sprintf('You -> %s: %s', dst, msg));
    
    success = tx_chain(msg, data.txSDR, src, dst);
    
    if success
        addChat(fig, 'System: Sent!');
    else
        addChat(fig, 'System: TX failed');
    end
    
    set(data.msgEdit, 'String', '');
    data.sm.finishTransmit();
    set(data.sendBtn, 'Enable', 'off');
    set(data.requestBtn, 'Enable', 'on');
    updateStatus(fig);
    
    guidata(fig, data);
end

function pingCallback(~, ~, fig)
    data = guidata(fig);
    
    if isempty(data.txSDR) || isempty(data.rxSDR)
        addChat(fig, 'System: Connect radios before pinging');
        return;
    end
    
    if ~data.sm.requestTransmit()
        addChat(fig, 'System: TX busy, try again');
        return;
    end
    
    data.pingId = randi([0, 1e6]);
    data.pingStart = tic;
    data.pingPending = true;
    guidata(fig, data);
    updateStatus(fig);
    
    src = get(data.sourceEdit, 'String');
    dst = get(data.destEdit, 'String');
    
    addChat(fig, sprintf('System: PING → %s', dst));
    success = tx_chain(sprintf('PING:%d', data.pingId), data.txSDR, src, dst);
    
    data = guidata(fig);
    if success
        addChat(fig, 'System: Ping sent, waiting for reply...');
    else
        addChat(fig, 'System: Ping transmit failed');
        data.pingPending = false;
    end
    
    data.sm.finishTransmit();
    guidata(fig, data);
    updateStatus(fig);
end

function addChat(fig, msg)
    data = guidata(fig);
    timestamp = datestr(now, 'HH:MM:SS');
    newMsg = sprintf('[%s] %s', timestamp, msg);
    current = get(data.chatList, 'String');
    set(data.chatList, 'String', [current; {newMsg}]);
    set(data.chatList, 'Value', length(current)+1);
    guidata(fig, data);
end

function updateStatus(fig)
    data = guidata(fig);
    set(data.statusText, 'String', sprintf('Status: %s', data.sm.state));
    guidata(fig, data);
end

function startRXTimer(fig)
    data = guidata(fig);
    
    if ~isempty(data.rxTimer)
        stop(data.rxTimer);
        delete(data.rxTimer);
    end
    
    data.rxTimer = timer('ExecutionMode', 'fixedRate', ...
                         'Period', 2, ...
                         'TimerFcn', @(~,~) checkForMessages(fig));
    start(data.rxTimer);
    
    guidata(fig, data);
end

function checkForMessages(fig)
    if ~ishandle(fig)
        return;
    end
    
    data = guidata(fig);
    
    if isempty(data.rxSDR) || ~data.sm.canReceive()
        return;
    end
    
    try
        [message, valid, sourceCall, ~] = rx_chain(data.rxSDR, 2);
        
        if valid && ~isempty(message)
            msgTrim = strtrim(message);
            
            if handlePingReply(fig, msgTrim, sourceCall)
                return;
            end
            
            if handlePingRequest(fig, msgTrim, sourceCall)
                return;
            end
            
            addChat(fig, sprintf('%s: %s', sourceCall, msgTrim));
        end
    catch
        % ignore RX errors
    end
end

function handled = handlePingReply(fig, msgTrim, sourceCall)
    handled = false;
    data = guidata(fig);
    
    if startsWith(msgTrim, 'PONG:')
        parts = split(msgTrim, ':');
        pongId = NaN;
        if numel(parts) >= 2
            pongId = str2double(parts{2});
        end
        
        if data.pingPending && ~isnan(pongId) && pongId == data.pingId
            rtt = round(toc(data.pingStart) * 1000);
            addChat(fig, sprintf('System: Pong from %s in %d ms', sourceCall, rtt));
            data.pingPending = false;
            guidata(fig, data);
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
        
        addChat(fig, sprintf('System: Ping request from %s (id %s)', sourceCall, pingId));
        sendPong(fig, sourceCall, pingId);
        handled = true;
    end
end

function sendPong(fig, destCall, pingId)
    data = guidata(fig);
    
    if isempty(data.txSDR)
        return;
    end
    
    if ~data.sm.requestTransmit()
        addChat(fig, 'System: Busy, unable to answer ping now');
        return;
    end
    
    src = get(data.sourceEdit, 'String');
    ackMsg = sprintf('PONG:%s', pingId);
    success = tx_chain(ackMsg, data.txSDR, src, destCall);
    
    if success
        addChat(fig, sprintf('System: Pong → %s', destCall));
    else
        addChat(fig, sprintf('System: Failed to respond to ping from %s', destCall));
    end
    
    data.sm.finishTransmit();
    guidata(fig, data);
    updateStatus(fig);
end
