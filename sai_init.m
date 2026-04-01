function S = sai_init()
% SAI_INIT  Initialize Snap & Identify shared resources.
%   S = sai_init() returns a struct with:
%     S.net       - loaded GoogLeNet network
%     S.inputSize - [H W] input size for the network
%     S.emojiMap  - containers.Map of GoogLeNet labels -> emoji

    % Workaround: R2026a prerelease support package path
    if isfolder('C:\ProgramData\MATLAB\SupportPackages\R2026aPrerelease') && ...
            isempty(matlabshared.supportpkg.getSupportPackageRoot)
        matlabshared.supportpkg.setSupportPackageRoot(...
            'C:\ProgramData\MATLAB\SupportPackages\R2026aPrerelease');
    end

    S.net = googlenet;
    S.inputSize = S.net.Layers(1).InputSize(1:2);
    S.emojiMap = sai_buildEmojiMap();
end
