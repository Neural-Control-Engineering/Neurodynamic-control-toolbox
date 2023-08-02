function [property] = getProperty(string)
%GETPROPERTY Grab the relevant column from the tall array storing all data
%   This function serves to map all the columns in the Datastore to the
%   relevant property name. It makes accessing specific types of data
%   easier.

switch string
    case "session id"
        property = 1;
    case "session date"
        property = 2;
    case "paradigm"
        property = 3;
    case "phase"
        property = 4;
    case "sequential session number"
        property = 5;
    case "session trial number"
        property = 6;
    case "ISI" % inter-stimulus interval
        property = 7;
    case "trial onset time"
        property = 8;
    case "trial stimulus time"
        property = 9;
    case "trial stimulus strength"
        property = 10;
    case "trial lick times"
        property = 11;
    case "trial response times"
        property = 12;    
    case "trial go/no-go"
        property = 13;
    case "delayed response"
        property = 14;
    case "categorical outcome"
        property = 15;
    case "previous trial categorical outcome"
        property = 16;
    case "onset tone to stim delay"
        property = 17;
    case "distractor puff times"
        property = 18;
    case "channel 1 photometry region"
        property = 19;
    case "channel 1 photometry 5th%"
        property = 20;
    case "channel 1 photometry 95th%"
        property = 21;
    case "channel 2 photometry region"
        property = 22;
    case "channel 2 photometry 5%"
        property = 23;
    case "channel 2 photometry 95%"
        property = 24;
    case "session optogenetic manipulation"
        property = 25;
    case "session chemogenetic/pharmacologic manipulation"
        property = 26;
    case "session chemogenetic/pharmacologic dosage"
        property = 27;
    case "baseline pupil window"
        property = 28;
    case "pupil baseline - onset tone"
        property = 29;
    case "pupil baseline - stimulus"
        property = 30;
    case "trial pupil area"
        property = 31;
    case "session pupil 5th%"
        property = 32;
    case "session pupil 95th%"
        property = 33;
    case "baseline photometry window"
        property = 34;
    case "channel 1 photometry baseline - onset tone"
        property = 35;
    case "channel 1 photometry baseline - stimulus"
        property = 36;
    case "channel 1 photometry data"
        property = 37;
    case "channel 2 photometry baseline - onset tone"
        property = 38;
    case "channel 2 photometry baseline - stimulus"
        property = 39;
    case "channel 2 photometry data"
        property = 40;
    case "trial whisker data"
        property = 41;
    case "wheel displacement"
        property = 42;
%     case ""
%         property = 43;
    case "optogenetic pulse start time"
        property = 44;
%     case ""
%         property = 45;
%     case ""
%         property = 46;
    case "session psychometric curve"
        property = 47;
    case "dprime"
        property = 48;
    case "criterion"
        property = 49;
    otherwise
        property = NaN;

end