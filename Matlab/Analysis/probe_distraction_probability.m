% probe distraction
% checks the probability that a probe will attract a saccade
function diffAngles = probe_distraction_probability(Trials,plotFlag)

if nargin<2
    plotFlag=0;
end

diffAngles=[];
for i = 1:length(Trials)
    saccs = Trials(i).Saccades;
    saccsXY_time_start=[];
    saccsXY_time_end=[];
    fixXY_time_start=[];
    for s = 1:length(saccs)
        saccsXY_time_start(s,:)=[saccs(s).x_sacc_start saccs(s).y_sacc_start saccs(s).t_start_sacc];
        saccsXY_time_end(s,:)=[saccs(s).x_sacc_end saccs(s).y_sacc_end saccs(s).t_end_sacc];
        fixXY_time_start(s,:)=[saccs(s).meanX_prev_fix saccs(s).meanY_prev_fix saccs(s).t_start_prev_fix];
    end
    
    probes = Trials(i).probeXY_time;
    % cycle through the probes
    for p = 1:size(probes,1)
        curprobe = probes(p,:);
        p_time = curprobe(3);

        
        % now grab all the post-probe saccades and take the first one
        postProbeSaccs = find(saccsXY_time_start(:,3)>p_time+80); % add 80 ms to account for SRT
        if ~isempty(postProbeSaccs)
            ppSacc_start = saccsXY_time_start(postProbeSaccs(1),:);
            ppSacc_end = saccsXY_time_end(postProbeSaccs(1),:);
            % now see what the vector of this saccade was, and calculate
            % the angle
            saccVec = ppSacc_end(1:2)-ppSacc_start(1:2);
            saccAng = atan2(saccVec(2),saccVec(1));
            
            % find out where the eye was fixated at p_time (probe time)
            ppFix_start = fixXY_time_start(postProbeSaccs(1),:);
            
            % now get angle subtending vector from fixation to probe
            probeVec = curprobe(1:2)-ppFix_start(1:2);
            probeAng = atan2(probeVec(2),probeVec(1));
            
            % now align saccade vector to the fixation-probe vector (i.e.,
            % subtract the fix-probe vector angle) in order to normalize
            diffAngles(end+1)=saccAng-probeAng;
            
        end
    end
end


diffAngles(diffAngles<0)=diffAngles(diffAngles<0)+(2*pi);
% convert to degrees?
diffAngles=diffAngles*(180/pi);

if plotFlag
    numbins=70;
    chance = length(diffAngles)/numbins/length(diffAngles);
    
    figure()
    [n,x]=hist(diffAngles,numbins);
    plot(x,n/length(diffAngles),'k','linewidth',2);
%     xlim([0 2*pi]) % radians
    xlim([0 (2*pi)*(180/pi)]) % degrees
    ylim([0 .05])
    title('Probability of Probe Attracting a Saccade')
    xlabel('Difference between saccade vector and fixation-probe vector (degrees)')
    ylabel('Percentage of instances')
    
end
        