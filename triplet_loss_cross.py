# -*- coding: utf-8 -*-
"""
Created on Wed Jun 19 09:40:46 2019

@author: checa
"""
from keras import backend as K
def triplet_loss_cross(_, y_pred, alpha = 1):
    """
    Implementation of the triplet loss function

    Arguments:
    y_true -- true labels, required when you define a loss in Keras, you don't need it in this function.
    y_pred -- python list containing three objects:
            anchor -- the encodings for the anchor data
            positive -- the encodings for the positive data (similar to anchor)
            negative -- the encodings for the negative data (different from anchor)

    Returns:
    loss -- real number, value of the loss

    """
    #y_pred = model_df
#    anchor, positive, negative = tf.split(y_pred,3,axis = 1)
    #y_pred = train_data
    outdime=16
    anchor = y_pred[:,0:outdime-1]
    anchor_tail = y_pred[:,outdime-1:outdime]
    positive = y_pred[:,outdime:2*outdime-1]
    positive_tail = y_pred[:,2*outdime-1:2*outdime]
    negative = y_pred[:,2*outdime:3*outdime-1]
    negative_tail = y_pred[:,3*outdime-1:3*outdime]
    #test = concatenate((anchor, positive),axis=1)
    # distance between the anchor and the positive
    pos_dist = K.sum(K.square(anchor-positive),axis=1)+K.sum(K.square(anchor_tail+positive_tail),axis=1)

    # distance between the anchor and the negative
    neg_dist = K.sum(K.square(anchor-negative),axis=1)+K.sum(K.square(anchor_tail+negative_tail),axis=1)
    # compute loss
    #basic_loss = (pos_dist)-neg_dist
    loss = pos_dist-K.minimum(neg_dist,.3)
    #loss=K.log(1+K.exp((pos_dist)*alpha))+K.log(1+K.exp(-(neg_dist)*alpha))
    return loss
