function lickRasterByStimStrength(data, session)
    data = filterTrials(data, 'session_id', session);
    stim_strengths = unique(data.stimulus_strength);
    for o = 1:length(stim_strengths)
        tmp = filterTrials(data, 'stim_strength', stim_strengths(o));
        fig = figure();
        tl = tiledlayout(2,1);
        axs(1) = nexttile;
        hold on
        fill([-4,0,0,-4],[0,0,size(tmp,1)+1,size(tmp,1)+1],'w', 'FaceAlpha', 0.3)
        fill([-2,0,0,-2],[0,0,size(tmp,1)+1,size(tmp,1)+1],'r', 'FaceAlpha', 0.3)
        fill([0,0.8,0.8,0],[0,0,size(tmp,1)+1,size(tmp,1)+1],'g', 'FaceAlpha', 0.3)
        fill([0.8,2.0,2.0,0.8],[0,0,size(tmp,1)+1,size(tmp,1)+1],'w', 'FaceAlpha', 0.3)
        binned_licks = zeros(1,10);
        highs = linspace(0.08,0.8,10);
        lows = linspace(0,0.72,10);
        for trial = 1:size(tmp,1)
            temp_licks = tmp.lick_times{trial,1}-tmp.stimulus_time(trial);
            if ~isempty(temp_licks)
                lick_dif = diff(temp_licks);
                licks = temp_licks(find(lick_dif>0.05)+1);
                licks = [temp_licks(1); licks];
                good_licks = licks(licks>0 & licks<=0.8);
                bad_licks = licks(licks<0 | licks>0.8);
                plot(good_licks, repmat(trial, 1, length(good_licks)), 'k.')
                plot(bad_licks, repmat(trial, 1, length(bad_licks)), '.', 'Color', [0.5,0.5,0.5])
                for i = 1:length(highs)
                    binned_licks(i) = binned_licks(i) + length(good_licks(good_licks>=lows(i) & good_licks<=highs(i)));
                end
            end
        end
        xlim([-4,2])
        ylim([0,size(tmp,1)+1])
        xticks([])
        axs(2) = nexttile;
        hold on
        fill([-4,0,0,-4],[0,0,max(binned_licks)+10,max(binned_licks)+10],'w', 'FaceAlpha', 0.3)
        fill([-2,0,0,-2],[0,0,max(binned_licks)+10,max(binned_licks)+10],'r', 'FaceAlpha', 0.3)
        fill([0,0.8,0.8,0],[0,0,max(binned_licks)+10,max(binned_licks)+10],'g', 'FaceAlpha', 0.3)
        fill([0.8,2.0,2.0,0.8],[0,0,max(binned_licks)+10,max(binned_licks)+10],'w', 'FaceAlpha', 0.3)
        bar(highs-0.04, binned_licks, 'k')
        xlim([-4,2])
        ylim([0,max(binned_licks)+10])
        yticks([])
        axes(axs(1))
        ylabel('Trial', 'FontSize', 14)
        axes(axs(2))
        ylabel({'Binned', 'Responses'}, 'FontSize', 14)
        xlabel(tl, 'Time (s)', 'FontSize', 14)
        title(tl, sprintf('%.1f PSI', stim_strengths(o)*10), 'FontSize', 16)
        saveas(fig, sprintf('Analysis/paper_figures/figure1/lick_hists/%s/%s_%.1fPSI.fig', session, session, stim_strengths(o)*10))
    end
    psych_curve = figure(); plot(data.pscho_curve{1}(1,:).*10, data.pscho_curve{1}(2,:), 'k')
    xlabel('Stimulus Strength (PSI)', 'FontSize', 16)
    ylabel('Response Probability', 'FontSize', 16)
    saveas(psych_curve, sprintf('Analysis/paper_figures/figure1/lick_hists/%s/psych_curve.fig', session))

end