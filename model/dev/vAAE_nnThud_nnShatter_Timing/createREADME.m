
function createREADME
pngDir = './FigFiles/';
dirList = dir(fullfile(pngDir,'*.png'));

gitDir = 'https://github.com/michaelfuhrman/glassbreak/blob/master/model/dev/vAAD_nnThud_nnShatter_Timing/FigFiles';

fid = fopen('FIGURES.md','a');
fprintf(fid,'\n\n\n');
for k = 1:length(dirList)
   s = ['![](' dirList(k).name ') <br />'];
   fprintf(fid,'%s\n',s);
end
fclose(fid);
return

%https://github.com/michaelfuhrman/glassbreak/blob/master/model/dev/vAAD_nnThud_nnShatter_Timing/FigFiles/DeclareShatter_LogBaselineAndZCR_GB_TestClip_Short_v1_16000TimingLogicV2.png?raw=true