function comparePhaseIItoIIItracesByAnimal(Datastore)
    % filter data
    data = filterTrials(Datastore.NE_dstore, 'recording_location', 'mPFC-S1');
    data = filterTrials(data, 'categorical_outcome', 'Hit');
    
    % constants 
    phases = {'Phase II', 'Phase III'};
    tbounds = [-0.5, 1.0];
    colors = ['b', 'r'];

    % create output directory
    outdir = 'Analysis/avgTracesAfterStim/comparePhaseByAnimal_v2/';
    if ~exist(outdir, 'dir')
        mkdir(outdir)
    end
    
    % loop over animals 
    animals = fetchAnimals(data);
    for a = 1:length(animals)
        animal = filterTrials(data, 'animal', num2str(animals(a)));
        fig = figure('Visible', 'off');
        hold on;
        % loop over phases
        for p = 1:length(phases)
            % avg photometry traces 
            tmp = filterTrials(animal, 'phase', phases{p});
            Fss = getFs(tmp, 'photometry_ch1');
            ch1mat = nan(size(tmp,1), round(max(Fss)*diff(tbounds)));
            ch2mat = ch1mat;
            starts = tmp.stimulus_time;
            for i = 1:size(tmp,1)
                if Fss(i) == max(Fss)
                    ch1 = tmp.photometry_ch1{i,1}(:,2);
                    ch2 = tmp.photometry_ch2{i,1}(:,2);
                    t = tmp.photometry_ch1{i,1}(:,1) - starts(i);
                    ch1 = ch1(t > tbounds(1) & t < tbounds(2));
                    ch2 = ch2(t > tbounds(1) & t < tbounds(2));
                    t = t(t > tbounds(1) & t < tbounds(2));
                    ch1mat(i,:) = ch1;
                    ch2mat(i,:) = ch2;
                end
            end
            % plotting 
            label = sprintf('%s: (n=%i)', phases{p}, size(ch1mat,1));
            subplot(2,1,1)
            hold on
            semshade(ch1mat, 0.3, colors(p), colors(p), t, [], label);
            subplot(2,1,2)
            hold on
            semshade(ch2mat, 0.3, colors(p), colors(p), t, [], label);
        end
        subplot(2,1,1)
        title(data.photometry_region_ch1{1,1})
        ylabel('NE')
        ylim([-3,3])
        subplot(2,1,2)
        title(data.photometry_region_ch2{1,1})
        ylabel('NE')
        xlabel('Time (s)')
        ylim([-3,3])
        legend()
        fname = sprintf('%s%i.png', outdir, animals(a));
        saveas(fig, fname)

    end
    
end

