function [ Chinese ] = isChinese( ch )
% 对于GB2312的字符（就是我们平时所说的区位），一个汉字对应于两个字节。 每个字节都是大于A0（十六进制,即160），
% 倘若，第一个字节大于A0，而第二个字节小于A0，那么它应当不是汉字（仅仅对于GB2312)
Chinese=zeros(size(ch),'logical');
for i=1:size(ch,1)
    for j=1:size(ch,2)
        info = unicode2native(ch(i,j));
        bytes = size(info,2);
        if (bytes == 2)
            Chinese(i,j) = 1;
        end
    end
end

