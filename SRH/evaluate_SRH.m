function evaluation_info =evaluate_SRH(Xtraining,Xtest,KNN_info,Param)

tmp_T=cputime;
Param = trainSRH(Xtraining, Param);
traintime=cputime-tmp_T;
evaluation_info.trainT=traintime;

ntest=size(Xtest,1);
ntraining=size(Xtraining,1);
L=size(Param.A,2);
II=1:ntraining;

tmp_T=cputime;
for j=1:L
    B_tst{j} = compressSRH( Xtest, Param.A{j}, Param.B{j} );
    B_trn{j} = compressSRH( Xtraining, Param.A{j}, Param.B{j} );
    Mask{j}=setdiff(II,Param.Mask{j});
    SizeL(j)=length(Param.Mask{j});
end
compressiontime=cputime-tmp_T;
evaluation_info.compressT=compressiontime;

%%
RR=0;PP=0;
block_size=Param.block_size;     %block_size=500 ��Ĵ�С
block_num=ntest/block_size;           %10000/500=20   �ֿ����Ŀ
for i_block=1:block_num           %1:20
    fprintf('%d ', i_block);
    D=zeros(block_size,ntraining,'uint8');  %500*50000��0����
    D=D+inf;                                                   %500*50000Ԫ��ȫΪ255�ľ���
    D2=zeros(block_size,ntraining,'single');  %500*50000��0����
    ibase=(i_block-1)*block_size;     %0��500��1000��1500��2000����������9500
    imax=min(i_block*block_size, ntest);   %i_block*500,10000; imax=i_block*500
    BlockIdx=ibase+1:imax;     %(i_block,BlockIdx)��(1,1:500)��(2,501:1500)��
    %(3,1001:2500)��(4,1501:3500)��(5,2001:4500), ```,(20,9501:19500)
    for j=1:L
        Dhamm = hammingDist(B_tst{j}(BlockIdx,:), B_trn{j});  %�������ݷֿ��������ݵ�
        % ��ѵ�����ݵĺ�������Dhamm BlockIdx�ĳ���*5000
        if(Param.doMask)
            Dhamm(:,Mask{j})=inf;
        end
        D=min(Dhamm,D);     %D BlockIdx�ĳ���*5000   ��һ����Ŀ����ʹDhamm
        %�����޲�Ҫ����255(2^8=256)
        D2=D2+single(Dhamm);   %D2 BlockIdx�ĳ���*5000  L����ϣ���������ۼ�
    end
    D2=D2/(max(max(D2))+1);     %��һ��������
    D2=single(D)+D2;
    [foo, Rank] = sort(D2, 2,'ascend');    %fooΪ�������밴ÿ����С��������
    %Rank�Ƕ�Ӧ����ǰ��λ��
    
    Rank=single(Rank);
    if(iscell(KNN_info.knn_p2))  %iscell(KNN_info.knn_p2)=0
        trueRank=KNN_info.knn_p2(BlockIdx);
        if(strcmp('ranking', Param.searchtype))
            eva_info = eva_ranking1(Rank, trueRank);
        else
            eva_info = eva_lookup1(Rank, trueRank, foo );
        end
    else
        trueRank=KNN_info.knn_p2(BlockIdx,:);     %ִ����� KNN_info.knn_p2Ϊ10000*1000��
        %10000Ϊ�������ݵ㣬1000Ϊ��Ӧѵ����������ò������ݵ��1000������
        if(strcmp('ranking', Param.searchtype))    %Ϊ��
            eva_info = eva_ranking(Rank, trueRank);   %ִ�����
        else
            eva_info = eva_lookup(Rank, trueRank, foo );
        end
    end
    
    %     Ri(i_block,:)=eva_info.recall;
    %     Pi(i_block,:)=eva_info.precision;
    %     Mi(i_block,:)=eva_info.M_set;
    
    RR=RR+eva_info.recall;
    PP=PP+eva_info.precision;
end

% evaluation_info.recall=mean(Ri);
% evaluation_info.precision=mean(Pi);
% evaluation_info.M_set=mean(Mi);
evaluation_info.recall=RR/block_num;
evaluation_info.precision=PP/block_num;
evaluation_info.M_set=eva_info.M_set;
evaluation_info.SizeL=SizeL;
