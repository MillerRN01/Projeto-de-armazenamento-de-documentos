import React, { useState, useEffect } from 'react';
import {
  Box,
  Stepper,
  Step,
  StepLabel,
  StepContent,
  Typography,
  Button,
  Paper,
  TextField,
  Avatar,
  Chip,
  CircularProgress,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
} from '@mui/material';
import {
  Check as ApproveIcon,
  Close as RejectIcon,
  Add as AddIcon,
} from '@mui/icons-material';
import { useAuth } from '../../contexts/AuthContext';
import api from '../../services/api';
import { useSnackbar } from 'notistack';

interface WorkflowStep {
  id: string;
  name: string;
  description: string;
  approver: {
    id: number;
    username: string;
  };
  status: 'pending' | 'approved' | 'rejected';
  comments?: string;
  completed_at?: string;
}

interface Workflow {
  id: string;
  status: 'active' | 'completed' | 'rejected';
  current_step: number;
  steps: WorkflowStep[];
  created_at: string;
  updated_at: string;
}

export const DocumentWorkflow: React.FC<{ documentId: string }> = ({ documentId }) => {
  const [workflow, setWorkflow] = useState<Workflow | null>(null);
  const [loading, setLoading] = useState(true);
  const [comment, setComment] = useState('');
  const [showAddStepDialog, setShowAddStepDialog] = useState(false);
  const [newStep, setNewStep] = useState({
    name: '',
    description: '',
    approver_id: '',
  });
  const { user } = useAuth();
  const { enqueueSnackbar } = useSnackbar();

  useEffect(() => {
    loadWorkflow();
  }, [documentId]);

  const loadWorkflow = async () => {
    try {
      const response = await api.get(`/documents/${documentId}/workflow`);
      setWorkflow(response.data);
    } catch (error) {
      console.error('Error loading workflow:', error);
      enqueueSnackbar('Error loading workflow', { variant: 'error' });
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async (stepId: string) => {
    try {
      await api.post(`/documents/${documentId}/workflow/steps/${stepId}/approve`, {
        comments: comment,
      });
      loadWorkflow();
      setComment('');
      enqueueSnackbar('Step approved successfully', { variant: 'success' });
    } catch (error) {
      console.error('Error approving step:', error);
      enqueueSnackbar('Error approving step', { variant: 'error' });
    }
  };

  const handleReject = async (stepId: string) => {
    try {
      await api.post(`/documents/${documentId}/workflow/steps/${stepId}/reject`, {
        comments: comment,
      });
      loadWorkflow();
      setComment('');
      enqueueSnackbar('Step rejected', { variant: 'info' });
    } catch (error) {
      console.error('Error rejecting step:', error);
      enqueueSnackbar('Error rejecting step', { variant: 'error' });
    }
  };

  const handleAddStep = async () => {
    try {
      await api.post(`/documents/${documentId}/workflow/steps`, newStep);
      loadWorkflow();
      setShowAddStepDialog(false);
      setNewStep({ name: '', description: '', approver_id: '' });
      enqueueSnackbar('Step added successfully', { variant: 'success' });
    } catch (error) {
      console.error('Error adding step:', error);
      enqueueSnackbar('Error adding step', { variant: 'error' });
    }
  };

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
        <CircularProgress />
      </Box>
    );
  }

  if (!workflow) {
    return (
      <Box sx={{ p: 3, textAlign: 'center' }}>
        <Typography variant="body1" gutterBottom>
          No workflow found for this document.
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => setShowAddStepDialog(true)}
        >
          Create Workflow
        </Button>
      </Box>
    );
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
        <Typography variant="h6">Workflow Status</Typography>
        <Chip
          label={workflow.status}
          color={
            workflow.status === 'completed' ? 'success' :
            workflow.status === 'rejected' ? 'error' : 'primary'
          }
        />
      </Box>

      <Stepper activeStep={workflow.current_step} orientation="vertical">
        {workflow.steps.map((step, index) => (
          <Step key={step.id}>
            <StepLabel
              optional={
                <Typography variant="caption">
                  {step.completed_at
                    ? `Completed on ${new Date(step.completed_at).toLocaleDateString()}`
                    : `Pending approval from ${step.approver.username}`}
                </Typography>
              }
            >
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                {step.name}
                <Chip
                  size="small"
                  label={step.status}
                  color={
                    step.status === 'approved' ? 'success' :
                    step.status === 'rejected' ? 'error' : 'default'
                  }
                />
              </Box>
            </StepLabel>
            <StepContent>
              <Box sx={{ mb: 2 }}>
                <Typography>{step.description}</Typography>
                {step.comments && (
                  <Paper sx={{ p: 2, mt: 2, bgcolor: 'grey.50' }}>
                    <Typography variant="body2" color="textSecondary">
                      Comments:
                    </Typography>
                    <Typography variant="body1">{step.comments}</Typography>
                  </Paper>
                )}
              </Box>

              {step.status === 'pending' && user?.id === step.approver.id && (
                <Box sx={{ mt: 2 }}>
                  <TextField
                    fullWidth
                    multiline
                    rows={3}
                    label="Comments"
                    value={comment}
                    onChange={(e) => setComment(e.target.value)}
                    sx={{ mb: 2 }}
                  />
                  <Box sx={{ display: 'flex', gap: 1 }}>
                    <Button
                      variant="contained"
                      color="success"
                      startIcon={<ApproveIcon />}
                      onClick={() => handleApprove(step.id)}
                    >
                      Approve
                    </Button>
                    <Button
                      variant="contained"
                      color="error"
                      startIcon={<RejectIcon />}
                      onClick={() => handleReject(step.id)}
                    >
                      Reject
                    </Button>
                  </Box>
                </Box>
              )}
            </StepContent>
          </Step>
        ))}
      </Stepper>

      {workflow.status === 'active' && (
        <Button
          sx={{ mt: 2 }}
          startIcon={<AddIcon />}
          onClick={() => setShowAddStepDialog(true)}
        >
          Add Step
        </Button>
      )}

      <Dialog
        open={showAddStepDialog}
        onClose={() => setShowAddStepDialog(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>Add Workflow Step</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 2 }}>
            <TextField
              label="Step Name"
              fullWidth
              value={newStep.name}
              onChange={(e) => setNewStep({ ...newStep, name: e.target.value })}
            />
            <TextField
              label="Description"
              fullWidth
              multiline
              rows={3}
              value={newStep.description}
              onChange={(e) => setNewStep({ ...newStep, description: e.target.value })}
            />
            <FormControl fullWidth>
              <InputLabel>Approver</InputLabel>
              <Select
                value={newStep.approver_id}
                onChange={(e) => setNewStep({ ...newStep, approver_id: e.target.value })}
                label="Approver"
              >
                {/* Add your user list here */}
                <MenuItem value="user1">User 1</MenuItem>
                <MenuItem value="user2">User 2</MenuItem>
              </Select>
            </FormControl>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShowAddStepDialog(false)}>Cancel</Button>
          <Button
            variant="contained"
            onClick={handleAddStep}
            disabled={!newStep.name || !newStep.approver_id}
          >
            Add Step
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};
