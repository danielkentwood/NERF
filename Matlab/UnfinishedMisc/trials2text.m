% trials2text.m  - Code to take the Trials data structure and hopefully
%                  convert it or import it into a plaintext format.

% Motivation: MATLAB is difficult and not really a great option for 
%             storing massive amounts of data. We think this might make
%             it easier to work with things in a more structured way
%             down the line.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Example usage:
% Load one of the files with Trials into memory, then,
% run

% trials2text( Trials )

% It's not working entirely yet, but that should give you some idea.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function txt = trials2text( structure )
  disp("<Trials>");
  
  struct2text( structure, 1, 2);
  
  disp("</Trials>");
end
