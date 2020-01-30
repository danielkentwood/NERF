function NAMES = fieldnamesr(S,varargin)
%FIELDNAMESR Get structure field names in recursive manner.
%
%   NAMES = FIELDNAMESR(S) returns a cell array of strings containing the
%   structure field names associated with s, the structure field names
%   of any structures which are fields of s, any structures which are
%   fields of fields of s, and so on.
%
%   NAMES = FIELDNAMESR(S,DEPTH) is an optional field which allows the depth
%   of the search to be defined. Default is -1, which does not limit the
%   search by depth. A depth of 1 will return only the field names of s
%   (behaving like FIELDNAMES). A depth of 2 will return those field
%   names, as well as the field names of any structure which is a field of
%   s.
%
%   NAMES = FIELDNAMESR(...,'full') returns the names of fields which are
%   structures, as well as the contents of those structures, as separate
%   cells. This is unlike the default where a structure-tree is returned.
%
%   NAMES = FIELDNAMESR(...,'prefix') returns the names of the fields
%   prefixed by the name of the input structure.
%
%   NAMES = FIELDNAMESR(...,'struct') returns only the names of fields
%   which are structures.
%
%   See also FIELDNAMES, ISFIELD, GETFIELD, SETFIELD, ORDERFIELDS, RMFIELD.

%   Developed in MATLAB 7.13.0.594 (2011b).
%   By AATJ (adam.tudorjones@pharm.ox.ac.uk). 2011-10-11. Released under
%   the BSD license.

%Set optional arguments to default settings, if they are not set by the
%caller.
if size(varargin,1) == 0
    optargs = {-1} ;
    optargs(1:length(varargin)) = varargin ;
    depth = optargs{:} ;
    
    full = [0] ; [prefix] = [0] ; [struct] = [0] ;
else
    if any(strcmp(varargin,'full') == 1)
        full = 1 ;
    else
        full = 0 ;
    end
    
    if any(strcmp(varargin,'prefix') == 1)
        prefix = 1 ;
    else
        prefix = 0 ;
    end
    
    if any(strcmp(varargin,'struct') == 1)
        struct = 1 ;
    else
        struct = 0 ;
    end
    
    if any(cellfun(@isnumeric,varargin) == 1)
        depth = varargin{find(cellfun(@isnumeric,varargin))} ;
    else
        depth = -1 ;
    end
end