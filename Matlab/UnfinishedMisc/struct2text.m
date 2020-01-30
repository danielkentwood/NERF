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

% struct2text( Trials(1), 0, 2)

% It's not working entirely yet, but that should give you some idea.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function txt = struct2text( structure, nesting, tab)

  if (~isstruct(structure))
      dataWithSpacings = sprintf("%s%s", string(blanks(tab*nesting)), string(structure));
      disp(dataWithSpacings);
  end;
  
  if (isstruct(structure))
      if (length(structure) == 1)
          for field = fieldnames(structure).'

              openXMLtag  = sprintf("%s<%s>", string(blanks(tab*nesting)), string(field));
              closeXMLtag = sprintf("%s</%s>", string(blanks(tab*nesting)), string(field));

              disp(openXMLtag);

              struct2text( structure.(char(field)) , nesting+1, tab);

              % Needs to be able to account for both struct and struct arrays.
              % Hm.

              disp(closeXMLtag);
          end;
      else
          for i = 1:length(structure)

              openXMLtag  = sprintf("%s<%s value=""%d"">", string(blanks(tab*nesting)), "fromStructArray", i);
              closeXMLtag = sprintf("%s</%s>", string(blanks(tab*nesting)), "fromStructArray");

              disp(openXMLtag);

              struct2text(structure(i).', nesting+1, tab);

              disp(closeXMLtag);
          end;
      end;
  end;
end
