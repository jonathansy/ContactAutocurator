function M = read_whisker_measurements_v3(filename)
%% Reads measurements files output from whisker tracking
% By Nathan Clack.
%
% CAVEAT   
% This function only reads the "V1" measurements format.
%
% See "measurements_convert" help for more information
% about available file formats and converting to/from
% the different formats.
%
% USAGE
% M = read_whisker_measurements(filename)
%
% <filename> is the full path to the file.
% <M> is the output measurements matrix.  It has the
%     following column format:
%
%     1.  whisker identity (-1:other, 0,1,2...:Whiskers)
%     2.  time (frame #)
%     3.  segment id
%     4.  length (px)
%     5.  tracing score
%     6.  angle at follicle (degrees)
%     7.  mean curvature (1/px)
%     8.  follicle position: x (px)
%     9.  follicle position: y (px)
%     10. tip position: x (px)
%     11. tip position: y (px)
%
%     and optionally (with a provided .bar file)
%     12. distance to center of bar
%
% EXAMPLE
%
% %% plot time course of follicle angle for whisker "0."
% >> M = read_whisker_measurements("test.measurements");
% >> mask = M(:,1)==0;   % select whisker "0"
% >> plot( M(mask,2), M(mask,6) );
%

%% open
[s,attr,id] = fileattrib(filename); % get abs path
if(s)
  measurements = mexLoadMeasurements(attr.Name);
else
  error(attr)
end

M = zeros(length(measurements),11);
M(:,1) = [measurements.label];
M(:,2) = [measurements.fid];
M(:,3) = [measurements.wid];
M(:,4) = [measurements.length];
M(:,5) = [measurements.score];
M(:,6) = [measurements.angle];
M(:,7) = [measurements.curvature];
M(:,8) = [measurements.follicle_x];
M(:,9) = [measurements.follicle_y];
M(:,10) = [measurements.tip_x];
M(:,11) = [measurements.tip_y];

%% Some relevant c-code.
%  See traj.h and measurements_io_v1.c
%
% typedef struct _Measurements
% { int row;           // offset from head of data buffer ... Note: the type limits size of table
%   int fid;
%   int wid;
%   int state;
%
%   int face_x;        // used in ordering whiskers on the face...roughly, the center of the face
%   int face_y;        //                                      ...does not need to be in image
%   int col_follicle_x; // index of the column corresponding to the folicle x position
%   int col_follicle_y; // index of the column corresponding to the folicle y position
%                                                                           
%   int valid_velocity;
%   int n;
%   double *data;     // array of n elements
%   double *velocity; // array of n elements - change in data/time
% } Measurements;
%
% Measurements *read_measurements_v1( FILE *fp, int *n_rows)
% { Measurements *table, *row;
%   static const int rowsize = sizeof( Measurements ) - 2*sizeof(double*); //exclude the pointers
%   double *head;
%   int n_measures;
%
%   fread( n_rows, sizeof(int), 1, fp);
%   fread( &n_measures, sizeof(int), 1, fp );
%
%   table = Alloc_Measurements_Table( *n_rows, n_measures );
%   head = table[0].data;
%   row = table + (*n_rows);
%
%   while( row-- > table )
%   { fread( row, rowsize, 1, fp );
%     row->row = (row->data - head)/sizeof(double);
%     fread( row->data, sizeof(double), n_measures, fp);
%     fread( row->velocity, sizeof(double), n_measures, fp);
%   }
%   return table;
% }
%
