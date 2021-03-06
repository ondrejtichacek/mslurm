
cls = slurm;
cls.host = 'nm3hpc.newark.rutgers.edu';  % The host name of the cluster
cls.localStorage = 'c:\temp';            % Staging area on the local client machine
cls.user = '';  % Your user name on the cluster
cls.keyfile = ''; %Provide the path to your RSA SSH auth file here.
cls.remoteStorage = '/work/klab/jobStorage/';   % Staging area on the cluster, also the working directory for Matlab when it starts on the cluster
cls.nodeTempDir = '/scratch/';              % Matlab will write temporary results here on the nodes.
cls.headRootDir = '/work/klab/';            % Final resuls will be copied here from the node.    

cls.connect; % Connect
cls.sacct; % Get the current accounting state 
% Open the GUI to see the jobs that the SLURM schedulre knows about (For
% the current user). This could be empty if you did not schedule any jobs
% yet (or if they were scheduled before the date selected in the calender).

slurmGui(cls);


%% Now schedule a simple job. We'll generate 5 matrices of 10x10  random
% numbers.
nrWorkers = 5;
data = 10*ones(nrWorkers,1);
options = {'partition','test'}; % Specify a partition and antyhing else the sbatch will accept (e.g. memory requirements)
tag = cls.feval('rand',data,'batchOptions',options); % This will call rand(data(1)) in one matlab sesssion, rand(data(2)) in another etc.
% Click refresh in the slurmGui to see these jobs
% Once they have completed, you can retrieve the results with 
results = cls.retrieve(tag);

%% Another example, using  a data struct array
% We have reaction time data from 3 subjects.
data = struct('name',{'Joe','Bill','Mary'},'rt',{[200 300 100],[200 333 1123],[123 300 200]});
% We want to use a cluster to analyze the data from each subject in a separate job.
tag = cls.feval('slurmAnalyzeRt',data);
% The slurmAnalyzeRt m functon is a simple function that takes one of the
% elements of the struct array as its input, and computes the mean reaction
% time.
% Once the jobs complete, retrieve the data. Each item int he cell array
% correponds to the output of a single job (a subject here).
meanRt = cls.retrieve(tag);


%% Use fileInFileOut
% Another variant of cluster based jobs takes a list of files, processes
% them with some function, and saves the results (on the cluster) in a new
% file. 
% Define a list of files to "analyze" (these files are in the matlab demos
% directory so they are likely to exist on the cluster)
files= {'earth.mat','flujet.mat','detail.mat','durer.mat'};
% Because these files exist on the Matlab path, we can set inPath to '' 
% The results will be stored in the OutPath directory (we choose
% cls.remoteStorage)
% and the OutTag will be appended to the result files : the result of
% slurmAnalyzeFile('earth.mat') will be stored as earth.whos.mat in the
% cls.remoteStorage directory
cls.fileInFileOut('slurmAnalyzeFile','InPath','','OutPath',cls.remoteStorage,'InFile',files,'OutTag','.whos');

% There is no built-in,automatic way to retrieve these data,it is assumed that you do
% this at the OS level (e.g. with rsync or scp). But we can have a look at the 
% output directory with a simple unix command.
cls.command(['ls ' cls.remoteStorage '*.whos.mat'])
% And, because we know the file names, we can retrieve them manually
resultFiles = strrep(files,'.mat','.whos.mat');
cls.get(resultFiles,cls.localStorage,cls.remoteStorage);% 
%This will get the files from cls.remoteStorage and put them in the
%localStorage. (You can specify deleteRemote argument to remove the files
%from cluster storage)
% 
% Now we can open one of the files
load(fullfile(cls.localStorage,resultFiles{1}));
% This will put a variable called 'result' in the current workspace, which
% contains the result of slurmAnalyzeFile(files{1}). We can now use the
% results of this "analysis" of the file:
disp(['The file ' files{1} ' contains ' num2str(numel(result)) ' variables, with a total of ' num2str(sum([result.bytes])) ' bytes']);

%% Here's another useful function to make sure your mslurm installation on
% the server is up to date
mslurmPath = '~/Documents/MATLAB/mslurm';
cls.gitpull(mslurmPath);  % Pull from the origin on git.
% This could also be useful to make sure the code you developed on your
% client is updated on the server. For instance, if your github repo for
% your code lives in 
myGithub = '~/Documents/MATLAB/users';
cls.gitpull(myGithub);  % Pull from the origin on git.

%% And for troubleshooting, the slurmDiagnosis function can come in handy
% (you can edit/update it with your own diagnostic commands).
cls.feval('slurmDiagnose','basic')
% Once completed, load the output file by pressing 'o' in the gui.




