classdef half_duplex_sm < handle
    % HALF_DUPLEX_SM Half-duplex state machine for SDR communication
    %
    % Manages three states: IDLE, TRANSMIT, RECEIVE
    % Ensures only one side transmits at a time
    
    properties
        state           % Current state: 'IDLE', 'TRANSMIT', 'RECEIVE'
        requestTX       % Flag indicating TX request
        allowRemoteTX   % Flag to allow remote transmission
    end
    
    properties (Constant)
        STATE_IDLE = 'IDLE';
        STATE_TRANSMIT = 'TRANSMIT';
        STATE_RECEIVE = 'RECEIVE';
    end
    
    methods
        function obj = half_duplex_sm()
            % Constructor - initialize to IDLE state
            obj.state = obj.STATE_IDLE;
            obj.requestTX = false;
            obj.allowRemoteTX = true;
        end
        
        function success = requestTransmit(obj)
            % Request permission to transmit
            % Returns true if granted, false if denied
            
            if strcmp(obj.state, obj.STATE_IDLE) || strcmp(obj.state, obj.STATE_RECEIVE)
                obj.requestTX = true;
                obj.state = obj.STATE_TRANSMIT;
                obj.allowRemoteTX = false;
                success = true;
            else
                % Already transmitting
                success = false;
            end
        end
        
        function finishTransmit(obj)
            % Complete transmission and return to receive mode
            
            if strcmp(obj.state, obj.STATE_TRANSMIT)
                obj.state = obj.STATE_RECEIVE;
                obj.requestTX = false;
                obj.allowRemoteTX = true;
            end
        end
        
        function enterReceiveMode(obj)
            % Enter receive mode (default state after IDLE)
            
            if strcmp(obj.state, obj.STATE_IDLE) || strcmp(obj.state, obj.STATE_TRANSMIT)
                obj.state = obj.STATE_RECEIVE;
                obj.allowRemoteTX = true;
                obj.requestTX = false;
            end
        end
        
        function enterIdleMode(obj)
            % Enter idle mode
            
            obj.state = obj.STATE_IDLE;
            obj.requestTX = false;
            obj.allowRemoteTX = true;
        end
        
        function can = canTransmit(obj)
            % Check if transmission is allowed
            
            can = strcmp(obj.state, obj.STATE_TRANSMIT);
        end
        
        function can = canReceive(obj)
            % Check if reception is allowed
            
            can = strcmp(obj.state, obj.STATE_RECEIVE) || strcmp(obj.state, obj.STATE_IDLE);
        end
        
        function status = getStatus(obj)
            % Get current status as structure
            
            status.state = obj.state;
            status.requestTX = obj.requestTX;
            status.allowRemoteTX = obj.allowRemoteTX;
            status.canTransmit = obj.canTransmit();
            status.canReceive = obj.canReceive();
        end
        
        function str = getStateString(obj)
            % Get state as formatted string
            
            switch obj.state
                case obj.STATE_IDLE
                    str = '⚪ IDLE';
                case obj.STATE_TRANSMIT
                    str = '🟢 TX';
                case obj.STATE_RECEIVE
                    str = '🔵 RX';
                otherwise
                    str = '❓ UNKNOWN';
            end
        end
    end
end
